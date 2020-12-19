require_relative 'client'

module MarianaApi::CustomerApi
  class Client
    attr_reader :http_client

    def initialize(partner_credentials, subdomain, user_token = nil)
      @http_client = MarianaApi::Client.new(
        partner_credentials,
        subdomain,
        user_token
      )
    end
  end
end
