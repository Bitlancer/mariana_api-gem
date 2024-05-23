module MarianaApi::AdminApi::Resources
  class Sites
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/sites', params: params)
    end

    def read(id, params = {})
      @http_client.get("/api/sites/#{id}", params: params)
    end
  end
end
