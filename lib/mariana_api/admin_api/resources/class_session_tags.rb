# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Resources
      class ClassSessionTags
        def initialize(http_client)
          @http_client = http_client
        end

        def list(params = {})
          @http_client.get('/api/class_session_tags', params: params)
        end

        def read(id, params = {})
          @http_client.get("/api/class_session_tags/#{id}", params: params)
        end
      end
    end
  end
end
