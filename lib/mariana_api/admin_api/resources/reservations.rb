module MarianaApi::AdminApi::Resources
  class Reservations
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/reservations', params: params).force
    end

    def read(id, params = {})
      @http_client.get("/api/reservations/#{id}", params: params)
    end

    def create(params)
      @http_client.post('/api/reservations', params: params)
    end

    def assign_to_spot(id, params = {})
      @http_client.post("/api/reservations/#{id}/assign_to_spot", params: params)
    end

    def cancel(id, params = {})
      @http_client.post("/api/reservations/#{id}/cancel", params: params)
    end
  end
end
