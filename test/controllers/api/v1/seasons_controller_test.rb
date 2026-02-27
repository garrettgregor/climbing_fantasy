require "test_helper"

class Api::V1::SeasonsControllerTest < ActionDispatch::IntegrationTest
  test "GET /api/v1/seasons returns all seasons" do
    get api_v1_seasons_path
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("data")
    assert json.key?("meta")
    assert_equal Season.count, json["meta"]["total"]
  end

  test "GET /api/v1/seasons returns expected fields" do
    get api_v1_seasons_path
    json = JSON.parse(response.body)
    season = json["data"].first

    assert season.key?("id")
    assert season.key?("name")
    assert season.key?("year")
  end

  test "GET /api/v1/seasons/:id returns season with events" do
    season = seasons(:season_2024)
    get api_v1_season_path(season)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal season.id, json["data"]["id"]
    assert_equal season.name, json["data"]["name"]
    assert json["data"].key?("events")
  end

  test "GET /api/v1/seasons/:id returns 404 for missing season" do
    get api_v1_season_path(id: 999999)
    assert_response :not_found

    json = JSON.parse(response.body)
    assert json.key?("error")
  end
end
