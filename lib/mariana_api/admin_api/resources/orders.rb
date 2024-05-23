module MarianaApi::AdminApi::Resources
  class Orders
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/orders', params: params)
    end

    def read(id, params = {})
      @http_client.get("/api/orders/#{id}", params: params)
    end
  end
end
