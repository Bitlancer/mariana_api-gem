# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Resources
      class EmployeePublicProfiles
        def initialize(http_client)
          @http_client = http_client
        end

        def list(params = {})
          auth_type = params.key?(:include) ? :auto : :none
          @http_client.get('/api/employee_public_profiles', params: params, auth_type: auth_type)
        end

        def read(id, params = {})
          auth_type = params.key?(:include) ? :auto : :none
          @http_client.get("/api/employee_public_profiles/#{id}", params: params, auth_type: auth_type)
        end
      end
    end
  end
end
