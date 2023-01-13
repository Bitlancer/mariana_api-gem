module MarianaApi::AdminApi::Resources
  class Memberships
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/memberships', params: params).force
    end

    def read(id, params = {})
      @http_client.get("/api/memberships/#{id}", params: params)
    end
  end
end
