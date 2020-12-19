module MarianaApi::AdminApi::Resources
  class Tenants
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/tenants', params: params).force
    end

    def read(id, params = {})
      @http_client.get("/api/tenants/#{id}", params: params)
    end
  end
end
