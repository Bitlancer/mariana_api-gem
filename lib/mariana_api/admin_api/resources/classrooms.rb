module MarianaApi::AdminApi::Resources
  class Classrooms
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/classrooms', params: params).force
    end

    def read(id, params = {})
      @http_client.get("/api/classrooms/#{id}", params: params)
    end
  end
end
