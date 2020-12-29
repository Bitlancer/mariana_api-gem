module MarianaApi::AdminApi::Resources
  class EmployeePublicProfiles
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/employee_public_profiles', params: params, auth_type: :none).force
    end

    def read(id, params = {})
      @http_client.get("/api/employee_public_profiles/#{id}", params: params, auth_type: :none)
    end
  end
end
