# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Resources
      class TimeClockShifts
        def initialize(http_client)
          @http_client = http_client
        end

        def list(params = {})
          @http_client.get('/api/time_clock_shifts', params: params)
        end

        def read(id, params = {})
          @http_client.get("/api/time_clock_shifts/#{id}", params: params)
        end
      end
    end
  end
end
