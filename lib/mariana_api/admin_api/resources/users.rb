# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Resources
      class Users
        def initialize(http_client)
          @http_client = http_client
        end

        def list(params = {})
          @http_client.get('/api/users', params: params)
        end

        def read(id = 'self', params = {})
          @http_client.get("/api/users/#{id}", params: params)
        end
      end
    end
  end
end
