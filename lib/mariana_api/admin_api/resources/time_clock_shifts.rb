module MarianaApi::AdminApi::Resources
  class TimeClockShifts
    def initialize(http_client)
      @http_client = http_client
    end

    def list(params = {})
      @http_client.get('/api/time_clock_shifts', params: params).force
    end

    def read(id, params = {})
      @http_client.get("/api/time_clock_shifts/#{id}", params: params)
    end
  end
end
