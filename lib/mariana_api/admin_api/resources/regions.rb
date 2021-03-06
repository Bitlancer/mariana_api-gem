module MarianaApi::AdminApi::Resources
  class Regions
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/regions', params: params).force
    end

    def read(id, params = {})
      @http_client.get("/api/regions/#{id}", params: params)
    end
  end
end
