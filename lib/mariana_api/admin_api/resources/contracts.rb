module MarianaApi::AdminApi::Resources
  class Contracts
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/contracts', params: params).force
    end

    def read(id, params = {})
      @http_client.get("/api/contracts/#{id}", params: params)
    end
  end
end
