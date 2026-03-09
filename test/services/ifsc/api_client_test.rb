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
      VCR.use_cassette("ifsc_api_client/get_event_1405") do
        data = @client.get_event(1405)

        assert_equal(1405, data["id"])
        assert(data.key?("d_cats"))
        assert(data.key?("starts_at"))
        assert(data.key?("location"))

        dcat = data.fetch("d_cats").find { |cat| cat["dcat_id"] == 3 } || data.fetch("d_cats").first
        assert(dcat.key?("top_3_results"))
        assert(dcat.key?("full_results_url"))
      end
    end

    test "#live returns active category rounds" do
      VCR.use_cassette("ifsc_api_client/get_live") do
        data = @client.live

        assert(data.key?("live"))
        assert_kind_of(Array, data["live"])
      end
    end

    test "#get_event_category_results returns full category standings across rounds" do
      VCR.use_cassette("ifsc_api_client/get_event_category_results_1405_3") do
        data = @client.get_event_category_results(1405, 3)

        assert(data.key?("event"))
        assert(data.key?("dcat"))
        assert(data.key?("category_rounds"))
        assert(data.key?("ranking"))
        assert_kind_of(Array, data["ranking"])
        assert_not(data["ranking"].empty?)

        athlete = data["ranking"].first
        assert(athlete.key?("rounds"))
        assert_kind_of(Array, athlete["rounds"])
        assert_not(athlete["rounds"].empty?)

        round = athlete["rounds"].first
        assert(round.key?("category_round_id"))
        assert(round.key?("round_name"))
      end
    end

    test "#get_category_round_results returns ranking data" do
      VCR.use_cassette("ifsc_api_client/get_category_round_results_9381") do
        data = @client.get_category_round_results(9381)

        assert_equal(9381, data["id"])
        assert_equal("Qualification", data["round"])
        assert(data.key?("ranking"))
        assert_kind_of(Array, data["ranking"])
        assert_not(data["ranking"].empty?)

        athlete = data["ranking"].first
        assert(athlete.key?("ascents"))
        assert_kind_of(Array, athlete["ascents"])
      end
    end

    test "#get_event_registrations returns registration array" do
      VCR.use_cassette("ifsc_api_client/get_event_registrations_1491") do
        data = @client.get_event_registrations(1491)

        assert_kind_of(Array, data)
        assert_not(data.empty?)

        registration = data.first
        assert(registration.key?("athlete_id"))
        assert(registration.key?("firstname"))
        assert(registration.key?("lastname"))
        assert(registration.key?("country"))
      end
    end

    test "#get_event_registrations handles partial payload with missing optional fields" do
      partial_payload = [
        {
          "athlete_id" => 999001,
          "firstname" => "Alex",
          "lastname" => "Sample",
          "country" => nil,
          "federation" => nil,
          "d_cats" => [],
        },
        {
          "athlete_id" => 999002,
          "firstname" => "Taylor",
          "lastname" => "Example",
        },
      ]

      stub_request(:get, "https://ifsc.results.info/api/v1/events/1491/registrations")
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: partial_payload.to_json,
        )

      data = VCR.turned_off { @client.get_event_registrations(1491) }

      assert_equal(2, data.length)
      assert_nil(data.first["country"])
      assert_nil(data.first["federation"])
      assert_equal([], data.first["d_cats"])
      assert_nil(data.second["country"])
      assert_nil(data.second["d_cats"])
    end

    test "#search_athletes returns array of matching athletes" do
      VCR.use_cassette("ifsc_api_client/search_athletes_janja") do
        data = @client.search_athletes("janja")

        assert_kind_of(Array, data)
        assert_not(data.empty?)

        athlete = data.first
        assert(athlete.key?("id"))
        assert(athlete.key?("firstname"))
        assert(athlete.key?("lastname"))
        assert(athlete.key?("gender"))
        assert(athlete.key?("ioc_code"))
      end
    end

    test "#get_athlete returns parsed athlete data" do
      VCR.use_cassette("ifsc_api_client/get_athlete_1147") do
        data = @client.get_athlete(1147)

        assert_equal(1147, data["id"])
        assert_equal("Janja", data["firstname"])
        assert_equal("GARNBRET", data["lastname"])
        assert(data.key?("country"))
        assert(data.key?("federation"))
        assert(data.key?("height"))
        assert_kind_of(Array, data["discipline_podiums"])
        assert_kind_of(Array, data["all_results"])
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
