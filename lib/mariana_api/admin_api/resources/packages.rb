module MarianaApi::AdminApi::Resources
  class Packages
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/packages', params: params).force
    end

    def read(id, params = {})
      @http_client.get("/api/packages/#{id}", params: params)
    end
  end
end
