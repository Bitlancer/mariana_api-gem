module MarianaApi::AdminApi::Resources
  class Locations
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/locations', params: params)
    end

    def read(id, params = {})
      @http_client.get("/api/locations/#{id}", params: params)
    end
  end
end
