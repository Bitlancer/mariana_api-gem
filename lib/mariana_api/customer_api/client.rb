require_relative 'client'

module MarianaApi::CustomerApi
  class Client
    attr_reader :http_client

    def initialize(http_client)
      @http_client = http_client
    end
  end
end
