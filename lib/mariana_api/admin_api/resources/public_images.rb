# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Resources
      class PublicImages
        def initialize(http_client)
          @http_client = http_client
        end

        def list(params = {})
          @http_client.get('/api/public_images', params: params, auth_type: :none)
        end

        def read(id, params = {})
          @http_client.get("/api/public_images/#{id}", params: params, auth_type: :none)
        end
      end
    end
  end
end
