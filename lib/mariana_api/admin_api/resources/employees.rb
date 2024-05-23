module MarianaApi::AdminApi::Resources
  class Employees
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/employees', params: params)
    end

    def read(id, params = {})
      @http_client.get("/api/employees/#{id}", params: params)
    end

    def create(params)
      @http_client.post('/api/employees', params: params)
    end
  end
end
