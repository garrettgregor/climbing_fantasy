module Ifsc
  class ApiClient
    BASE_URL = "https://ifsc.results.info"
    SESSION_COOKIE_NAME = "_verticallife_resultservice_session"

    class ApiError < StandardError; end

    def initialize
      @session_cookie = fetch_session_cookie
    end

    def get_season(id)
      get("/api/v1/seasons/#{id}")
    end

    def get_season_league(id)
      get("/api/v1/season_leagues/#{id}")
    end

    def get_event(id)
      get("/api/v1/events/#{id}")
    end

    def get_category_round_results(id)
      get("/api/v1/category_rounds/#{id}/results")
    end

    def get_event_registrations(id)
      get("/api/v1/events/#{id}/registrations")
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.headers["Cookie"] = "#{SESSION_COOKIE_NAME}=#{@session_cookie}"
        f.headers["Referer"] = "#{BASE_URL}/"
        f.headers["Accept"] = "application/json"
      end
    end

    def get(path)
      response = connection.get(path)
      unless response.success?
        raise ApiError, "HTTP #{response.status} for #{path}: #{response.body.truncate(200)}"
      end

      JSON.parse(response.body)
    rescue Faraday::Error => e
      raise ApiError, "Request failed for #{path}: #{e.message}"
    end

    def fetch_session_cookie
      response = Faraday.get(BASE_URL)
      cookie_header = response.headers["set-cookie"]
      raise ApiError, "No session cookie returned from #{BASE_URL}" unless cookie_header

      match = cookie_header.match(/#{SESSION_COOKIE_NAME}=([^;]+)/)
      raise ApiError, "Session cookie '#{SESSION_COOKIE_NAME}' not found in response" unless match

      match[1]
    rescue Faraday::Error => e
      raise ApiError, "Failed to fetch session cookie: #{e.message}"
    end
  end
end
