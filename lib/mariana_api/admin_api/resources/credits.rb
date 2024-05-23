module MarianaApi::AdminApi::Resources
  class Credits
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/credits', params: params)
    end

    def read(id, params = {})
      @http_client.get("/api/credits/#{id}", params: params)
    end
  end
end
