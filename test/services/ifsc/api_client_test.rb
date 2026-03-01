require "test_helper"

module Ifsc
  class ApiClientTest < ActiveSupport::TestCase
    setup do
      @client = VCR.use_cassette("ifsc_api_client/session") { ApiClient.new }
    end

    test "acquires session cookie on initialization" do
      VCR.use_cassette("ifsc_api_client/session") do
        client = ApiClient.new
        assert_instance_of(ApiClient, client)
      end
    end

    test "raises ApiError when session cookie is missing" do
      stub_request(:get, "https://ifsc.results.info/")
        .to_return(status: 200, headers: {}, body: "")

      assert_raises(ApiClient::ApiError) do
        VCR.turned_off { ApiClient.new }
      end
    end

    test "#get_season returns parsed season data" do
      VCR.use_cassette("ifsc_api_client/get_season_38") do
        data = @client.get_season(38)

        assert_equal("2026", data["name"])
        assert_kind_of(Array, data["leagues"])
        assert_kind_of(Array, data["events"])
        assert_not(data["events"].empty?)

        event = data["events"].first
        assert(event.key?("event_id"))
        assert(event.key?("event"))
        assert(event.key?("location"))
      end
    end

    test "#get_season_league returns parsed league data" do
      VCR.use_cassette("ifsc_api_client/get_season_league_457") do
        data = @client.get_season_league(457)

        assert_equal("2026", data["season"])
        assert_kind_of(Array, data["d_cats"])
        assert_kind_of(Array, data["events"])
      end
    end

    test "#get_event returns parsed event data with d_cats" do
      VCR.use_cassette("ifsc_api_client/get_event_1491") do
        data = @client.get_event(1491)

        assert_equal(1491, data["id"])
        assert(data.key?("d_cats"))
        assert(data.key?("starts_at"))
        assert(data.key?("location"))
      end
    end

    test "#get_category_round_results returns ranking data" do
      VCR.use_cassette("ifsc_api_client/get_category_round_results_10468") do
        data = @client.get_category_round_results(10468)

        assert(data.key?("ranking"))
        assert_kind_of(Array, data["ranking"])
      end
    end

    test "#get_event_registrations returns registration array" do
      VCR.use_cassette("ifsc_api_client/get_event_registrations_1491") do
        data = @client.get_event_registrations(1491)

        assert_kind_of(Array, data)
        return if data.empty?

        registration = data.first
        assert(registration.key?("athlete_id"))
        assert(registration.key?("firstname"))
        assert(registration.key?("lastname"))
        assert(registration.key?("country"))
      end
    end

    test "raises ApiError on HTTP error response" do
      VCR.use_cassette("ifsc_api_client/error_404") do
        assert_raises(ApiClient::ApiError) do
          @client.get_season(999999)
        end
      end
    end
  end
end
