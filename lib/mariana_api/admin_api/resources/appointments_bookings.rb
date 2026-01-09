# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Resources
      class AppointmentsBookings
        def initialize(http_client)
          @http_client = http_client
        end

        def list(params = {})
          params[:per_page] = 25 unless params.key?(:per_page)
          @http_client.get('/api/appointments/bookings', params: params)
        end

        def read(id, params = {})
          @http_client.get("/api/appointments/bookings/#{id}", params: params)
        end
      end
    end
  end
end
