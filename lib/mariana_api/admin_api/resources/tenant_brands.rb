module MarianaApi::AdminApi::Resources
  class TenantBrands
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/tenant_brands', params: params, auth_type: :none)
    end

    def read(id, params = {})
      @http_client.get("/api/tenant_brands/#{id}", params: params, auth_type: :none)
    end
  end
end
