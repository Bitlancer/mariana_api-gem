# frozen_string_literal: true

require_relative 'client'

module MarianaApi
  module CustomerApi
    class Client
      attr_reader :http_client

      def initialize(http_client)
        @http_client = http_client
      end
    end
  end
end
