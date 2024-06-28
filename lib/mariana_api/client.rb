# frozen_string_literal: true

require 'async'
require 'async/semaphore'
require 'logger'
require 'net/http'
require 'oauth2'
require 'ostruct'
require 'securerandom'

module MarianaApi
  class Client
    REQUEST_TIMEOUT = 90

    attr_accessor :logger, :log_http_transactions, :subdomain, :on_token_refresh

    def initialize(partner_credentials, subdomain, user_token = nil)
      partner_credentials.transform_keys!(&:to_sym)
      user_token&.transform_keys!(&:to_sym)

      @logger = Logger.new($stdout)
      @log_http_transactions = false

      @on_token_refresh = nil

      %i[client_id redirect_uri].each do |req_key|
        raise "refresh_params must contain #{req_key}" unless partner_credentials.key?(req_key)
      end
      @partner_credentials = partner_credentials

      @subdomain = subdomain
      raise 'subdomain must be set' if subdomain.nil?

      @user_token = nil
      return if user_token.nil?

      %i[refresh_token].each do |req_key|
        raise "user_token must contain #{req_key}" unless user_token.key?(req_key)
      end
      user_token.merge!({ expires_latency: 60 })
      @user_token = OAuth2::AccessToken.from_hash(oauth_client, user_token)
    end

    def admin_api_client
      require_relative 'admin_api'
      AdminApi::Client.new(self)
    end

    def customer_api_client
      require_relative 'customer_api'
      CustomerApi::Client.new(self)
    end

    def get(endpoint, params: {}, auth_type: :auto, retries: 3, concurrency: 4)
      params = { page_size: 100 }.merge(params)
      params = params.transform_values { |v| v.is_a?(Array) ? v.join(',') : v }

      includes = params.key?(:include) ? params[:include].split(',') : []

      opts = {}
      opts[:retry_limit] = retries
      opts[:auth_type] = auth_type
      opts[:query] = params

      responses = []

      responses << api_request(:get, endpoint, opts)

      page_meta = responses[0].dig(:meta, :pagination)

      if page_meta.nil?
        return data_merge_included(
          [responses[0][:data]],
          includes,
          responses[0][:included]
        ).first
      end

      pages = page_meta[:pages]
      total_count = page_meta[:count]

      Async do
        semaphore = Async::Semaphore.new(concurrency)
        responses += (2..pages).map do |page|
          semaphore.async do |_task|
            task_opts = opts.dup
            task_opts[:query][:page] = page
            api_request(:get, endpoint, task_opts)
          end
        end.map(&:wait)
      end

      data = responses.map do |resp|
        data_merge_included(resp[:data], includes, resp[:included])
      end.flatten

      raise "Assertion error: data size #{data.size} != pagination count #{total_count}" if data.size != total_count

      data
    end

    def data_merge_included(data, includes, included_data)
      return data if includes.empty?

      if included_data.is_a?(Hash)
        included_data_map = included_data
      else
        included_data_map = Hash.new { |hash, key| hash[key] = {} }
        included_data.each do |obj|
          included_data_map[obj[:type].to_sym][obj[:id].to_sym] = obj
        end
      end

      data.each do |obj|
        includes.each do |include_key|
          next if include_key.include?('.')

          rel_objs_wrapper = obj[:relationships][include_key.to_sym]
          next if rel_objs_wrapper[:data].nil? || rel_objs_wrapper[:data].empty?

          rel_objs = if rel_objs_wrapper[:data].is_a?(Array)
                       rel_objs_wrapper[:data]
                     else
                       [rel_objs_wrapper[:data]]
                     end
          rel_objs.first[:type].to_sym
          rel_objs.each do |rel_obj|
            type = rel_obj[:type].to_sym
            id = rel_obj[:id].to_sym
            incl_obj = included_data_map[type].fetch(id, {})
            next if incl_obj.empty?

            child_includes = includes.select do |child_include_key|
              child_include_key.start_with?("#{include_key}.")
            end.map do |child_include_key|
              child_include_key.delete_prefix("#{include_key}.")
            end

            incl_obj = data_merge_included([incl_obj], child_includes, included_data_map).first

            rel_obj[:attributes] = incl_obj[:attributes]
            rel_obj[:relationships] = incl_obj[:relationships]
          end
        end
      end

      data
    end

    def post(endpoint, body: {}, auth_type: :auto)
      opts = {
        auth_type: auth_type,
        body: body
      }
      api_request(:post, endpoint, opts)
    end

    def api_request(method, endpoint, opts = {})
      raise 'invalid method' unless %i[get post].include?(method)

      opts = {
        auth_type: :auto,
        retry_limit: 0,
        retry_delay: 2,
        retry_attempt: 0
      }.merge(opts)

      auth_type = opts[:auth_type]
      raise 'invalid auth type' unless %i[auto token api_key none].include?(auth_type)

      if auth_type == :auto
        auth_type = if !@user_token.nil?
                      :token
                    elsif !@partner_credentials[:api_key].nil?
                      :api_key
                    else
                      :none
                    end
      end

      token = if auth_type == :token
                get_user_token[:access_token]
              elsif auth_type == :api_key
                @partner_credentials[:api_key]
              end

      uri = URI(!(endpoint =~ %r{^http(s)?://}).nil? ? endpoint : api_endpoint(endpoint))
      uri.query = URI.encode_www_form(opts[:query]) if opts.key?(:query)

      client = Net::HTTP.new(uri.host, uri.port, nil)
      client.set_debug_output($stdout) if @log_http_transactions
      client.use_ssl = true
      client.open_timeout = REQUEST_TIMEOUT
      client.read_timeout = REQUEST_TIMEOUT

      request = nil
      request = Net::HTTP::Get.new(uri) if method == :get
      request = Net::HTTP::Post.new(uri) if method == :post

      request['Authorization'] = "Bearer #{token}" unless token.nil?
      request['Content-Type'] = 'application/json'

      request.body = opts[:body] if opts.key?(:body)

      @logger.info("HTTP request: #{method} #{uri}")
      response = nil
      begin
        response = client.request(request)
        response_code = response.code.to_i
        raise Net::HTTPRetriableError.new(response.body, response) if response_code == 429 || response_code >= 500
      rescue Net::HTTPRetriableError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
        if opts[:retry_attempt] < opts[:retry_limit]
          opts[:retry_attempt] += 1
          retry_in = opts[:retry_delay]**opts[:retry_attempt]
          @logger.warn("Retrying request #{method} #{uri} in #{retry_in} secs that failed with: #{e.inspect}")
          sleep(retry_in)
          return api_request(method, uri.to_s, opts)
        end
        raise
      end

      JSON.parse(response.body, symbolize_names: true)
    end

    def get_user_token(auth_code: nil, code_verifier: nil)
      if !auth_code.nil?
        code_verifier = @oauth_pkce_params[:code_verifier] if code_verifier.nil?
        @user_token = oauth_client.auth_code.get_token(
          auth_code,
          client_id: oauth_client.id,
          code_verifier: code_verifier
        )
      else
        raise 'user_token is not set' if @user_token.nil?

        if @user_token.expired?
          @user_token = @user_token.refresh!
          token_hash = @user_token.to_hash.merge({ subdomain: @subdomain })
          @on_token_refresh&.call(token_hash)
        end
      end

      @user_token.to_hash
    end

    def get_authorize_url(pkce_params: nil, scopes: 'read:account')
      pkce_params = oauth_pkce_params if pkce_params.nil?
      oauth_client.auth_code.authorize_url({
                                             code_challenge: pkce_params[:code_challenge],
                                             code_challenge_method: pkce_params[:code_challenge_method],
                                             state: pkce_params[:state],
                                             redirect_uri: @partner_credentials[:redirect_uri],
                                             scope: scopes
                                           })
    end

    def oauth_pkce_params(code_verifier: nil, state: nil)
      @oauth_pkce_params = {}
      @oauth_pkce_params[:state] = state || SecureRandom.hex(24)
      @oauth_pkce_params[:code_verifier] = code_verifier || SecureRandom.hex(64)
      @oauth_pkce_params[:code_challenge] = Base64.urlsafe_encode64(
        Digest::SHA2.digest(@oauth_pkce_params[:code_verifier]),
        padding: false
      )
      @oauth_pkce_params[:code_challenge_method] = 'S256'
      @oauth_pkce_params.freeze
    end

    def oauth_client
      @oauth_client ||= OAuth2::Client.new(
        @partner_credentials[:client_id],
        '',
        site: api_endpoint,
        authorize_url: '/o/authorize',
        token_url: '/o/token',
        token_method: :post_with_query_string,
        logger: (@log_http_transactions ? @logger : nil)
      ) do |faraday_conn|
        faraday_conn.options.timeout = REQUEST_TIMEOUT
      end
      @oauth_client
    end

    def api_endpoint(endpoint = '')
      "https://#{@subdomain}.marianatek.com" + endpoint
    end

    def self.valid_subdomain?(subdomain)
      begin
        resp = Net::HTTP.get_response(URI("https://#{subdomain}.marianatek.com/api/"))
        return resp.code.to_i == 200
      rescue StandardError
      end
      false
    end
  end
end
