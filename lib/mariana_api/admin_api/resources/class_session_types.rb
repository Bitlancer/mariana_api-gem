module MarianaApi::AdminApi::Resources
  class ClassSessionTypes
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/class_session_types', params: params)
    end

    def read(id, params = {})
      @http_client.get("/api/class_session_types/#{id}", params: params)
    end
  end
end
