require "test_helper"

class Api::V1::EventsControllerTest < ActionDispatch::IntegrationTest
  test "GET /api/v1/events returns all events" do
    get api_v1_events_path
    assert_response :success

    json = JSON.parse(response.body)
    assert json.key?("data")
    assert json.key?("meta")
    assert_equal Event.count, json["meta"]["total"]
  end

  test "GET /api/v1/events returns expected fields" do
    get api_v1_events_path
    json = JSON.parse(response.body)
    event = json["data"].first

    assert event.key?("id")
    assert event.key?("name")
    assert event.key?("location")
    assert event.key?("starts_on")
    assert event.key?("ends_on")
    assert event.key?("discipline")
    assert event.key?("status")
  end

  test "GET /api/v1/events filters by season_id" do
    season = seasons(:season_2024)
    get api_v1_events_path(season_id: season.id)
    json = JSON.parse(response.body)

    json["data"].each do |event|
      assert_equal season.id, event["season_id"]
    end
  end

  test "GET /api/v1/events filters by discipline" do
    get api_v1_events_path(discipline: "boulder")
    json = JSON.parse(response.body)

    json["data"].each do |event|
      assert_equal "boulder", event["discipline"]
    end
  end

  test "GET /api/v1/events filters by status" do
    get api_v1_events_path(status: "completed")
    json = JSON.parse(response.body)

    json["data"].each do |event|
      assert_equal "completed", event["status"]
    end
  end

  test "GET /api/v1/events filters by year" do
    get api_v1_events_path(year: 2024)
    json = JSON.parse(response.body)

    assert json["data"].length > 0
    json["data"].each do |event|
      assert_equal seasons(:season_2024).id, event["season_id"]
    end
  end

  test "GET /api/v1/events/:id returns event with categories" do
    event = events(:innsbruck_boulder)
    get api_v1_event_path(event)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal event.id, json["data"]["id"]
    assert json["data"].key?("categories")
    assert json["data"].key?("season")
  end

  test "GET /api/v1/events/:id returns 404 for missing" do
    get api_v1_event_path(id: 999999)
    assert_response :not_found
  end
end
