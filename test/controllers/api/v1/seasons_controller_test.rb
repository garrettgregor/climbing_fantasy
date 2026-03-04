require "test_helper"

module Api
  module V1
    class SeasonsControllerTest < ActionDispatch::IntegrationTest
      test "GET /api/v1/seasons returns all seasons" do
        get api_v1_seasons_path
        assert_response :success

        json = response.parsed_body
        assert json.key?("data")
        assert json.key?("meta")
        assert_equal Season.count, json["meta"]["total"]
      end

      test "GET /api/v1/seasons returns expected fields" do
        get api_v1_seasons_path
        json = response.parsed_body
        season = json["data"].first

        assert season.key?("id")
        assert season.key?("name")
        assert season.key?("year")
      end

      test "GET /api/v1/seasons clamps overflow page to last page" do
        get api_v1_seasons_path(page: 999, per_page: 1)
        assert_response :success

        json = response.parsed_body
        assert_equal Season.count, json["meta"]["page"]
        assert_equal 1, json["meta"]["per_page"]
        assert_equal 1, json["data"].length
      end

      test "GET /api/v1/seasons/:id returns season with events" do
        season = seasons(:season_2025)
        get api_v1_season_path(season)
        assert_response :success

        json = response.parsed_body
        assert_equal season.id, json["data"]["id"]
        assert_equal season.name, json["data"]["name"]
        assert json["data"].key?("events")
      end

      test "GET /api/v1/seasons/:id returns 404 for missing season" do
        get api_v1_season_path(id: 999999)
        assert_response :not_found

        json = response.parsed_body
        assert json.key?("error")
      end
    end
  end
end
