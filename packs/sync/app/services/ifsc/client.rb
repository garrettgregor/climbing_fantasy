module Ifsc
  class Client
    BASE_URL = "https://ifsc.results.info"

    class ApiError < StandardError; end

    def initialize(adapter: :net_http, stubs: nil)
      @connection = Faraday.new(url: BASE_URL) do |f|
        f.request(:json)
        f.response(:json, content_type: /\bjson$/)
        f.adapter(adapter, stubs)
      end
    end

    def fetch_seasons
      get("/results-api.php", api: "index")
    end

    def fetch_event_results(event_id)
      get("/results-api.php", api: "event_results", event_id: event_id)
    end

    def fetch_category_results(event_id, category_id)
      get("/api/v1/events/#{event_id}/result/#{category_id}")
    end

    private

    def get(path, params = {})
      response = @connection.get(path, params)

      unless response.success?
        raise ApiError, "HTTP #{response.status}: #{response.body}"
      end

      response.body
    end
  end
end
