require 'faraday'
require 'oauth2'
require 'ostruct'
require 'securerandom'

module MarianaApi
  class Client
    attr_accessor :logger, :http_logger
    attr_accessor :subdomain
    attr_accessor :on_api_request, :on_token_refresh

    def initialize(partner_credentials, subdomain, user_token = nil)
      partner_credentials.transform_keys!(&:to_sym)
      user_token.transform_keys!(&:to_sym) unless user_token.nil?

      @logger = nil
      @http_logger = nil

      @on_api_request = nil
      @on_token_refresh = nil

      for req_key in %i(client_id redirect_uri)
        raise "refresh_params must contain #{req_key}" unless partner_credentials.key?(req_key)
      end
      @partner_credentials = partner_credentials

      @subdomain = subdomain
      raise 'subdomain must be set' if subdomain.nil?

      @user_token = nil
      unless user_token.nil?
        for req_key in %i(refresh_token)
          raise "user_token must contain #{req_key}" unless user_token.key?(req_key)
        end
        user_token.merge!({ expires_latency: 60 })
        @user_token = OAuth2::AccessToken.from_hash(oauth_client, user_token)
      end
    end

    def admin_api_client
      require_relative 'admin_api'
      AdminApi::Client.new(self)
    end

    def customer_api_client
      require_relative 'customer_api'
      CustomerApi::Client.new(self)
    end

    def get(endpoint, params: {}, auth_type: :auto)
      params = { page_size: 100 }.merge(params)
      params = params.map { |k, v| [k, v.is_a?(Array) ? v.join(',') : v] }.to_h

      resp = request(:get, endpoint, params: params, auth_type: auth_type)
      page_meta = resp.dig(:meta, :pagination)

      includes = params.key?(:include) ? params[:include].split(',') : []

      if page_meta.nil?
        return data_merge_included(
          [resp[:data]],
          includes,
          resp[:included]
        ).first
      end

      Enumerator.new do |yielder|
        loop do
          data = data_merge_included(resp[:data], includes, resp[:included])
          data.each { |obj| yielder.yield obj }

          break if page_meta[:page] >= page_meta[:pages]
          params[:page] = page_meta[:page] + 1
          resp = request(:get, endpoint, params: params, auth_type: auth_type)
          page_meta = resp[:meta][:pagination]
        end
      end.lazy
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
          rel_objs_type = rel_objs.first[:type].to_sym
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

    def post(*args, **kwargs)
      request(:post, *args, **kwargs)
    end

    def request(method, endpoint, params: nil, auth_type: :auto)
      raise 'invalid method' unless %i[get post put patch delete]
      raise 'invalid auth type' unless %i[auto token api_key none]

      @on_api_request.call(method, endpoint, params) unless @on_api_request.nil?

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
              else
                nil
              end

      req_opts = Hash.new.tap do |opts|
        opts[:headers] = {}
        opts[:headers][:Authorization] = "Bearer #{token}" unless auth_type == :none
        opts[:headers][:'Content-Type'] = 'application/json'
        opts[:params] = params if params && %i(get delete).include?(method)
        opts[:body] = params.to_json if params && %i(post put).include?(method)
      end

      resp = nil
      if method == :get
        retries = 3; attempt = 1
        while true
          begin
            resp = oauth_client.request(method, endpoint, req_opts)
            break
          rescue => ex
            if ex.to_s =~ /timeout/i && attempt <= retries
              retry_in = 2**attempt
              unless @logger.nil?
                @logger.warn "Request #{method} #{endpoint} #{params} failed with #{ex}. Retrying in #{retry_in} secs"
              end
              sleep(retry_in)
              attempt += 1
            else
              raise
            end
          end
        end
      else
        resp = oauth_client.request(method, endpoint, req_opts)
      end

      JSON.parse(resp.body, symbolize_names: true)
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
          @on_token_refresh.call(token_hash) unless @on_token_refresh.nil?
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
        :padding => false,
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
        logger: @http_logger
      ) do |faraday_conn|
        faraday_conn.options.timeout = 90
      end
      @oauth_client
    end

    def api_endpoint
      "https://#{@subdomain}.marianatek.com"
    end

    def self.valid_subdomain?(subdomain)
      begin
        resp = Faraday.get "https://#{subdomain}.marianatek.com/api/"
        return resp.status == 200
      rescue
      end
      return false
    end
  end
end
