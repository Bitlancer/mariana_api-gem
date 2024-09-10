# frozen_string_literal: true

module MarianaApi
  module AdminApi
    module Resources
      class TableReports
        def initialize(http_client)
          @http_client = http_client
        end

        def list(params = {})
          @http_client.get('/api/table_reports', params: params)
        end

        def read(id, params = {})
          @http_client.get("/api/table_reports/#{id}", params: params)
        end

        def run(id, params = {}, polling_interval: 5, max_polls: 12)
          run_resp = @http_client.get("/api/async_table_report_data/#{id}", params: params)
          job_id = run_resp[:id]
          sleep polling_interval
          loop do
            status_resp = @http_client.get("/api/async_table_report_data/job_status", params: { id: job_id })
            if status_resp[:status] == 'processing'
              return status_resp if max_polls <= 0
              max_polls -= 1
              sleep polling_interval
              next
            end
            return status_resp if status_resp[:status] != 'complete'
            data_resp = Net::HTTP.get_response(URI(status_resp[:s3_link]))
            status_resp[:data] = JSON.parse(data_resp.body)
            return status_resp
          end
        end
      end
    end
  end
end
