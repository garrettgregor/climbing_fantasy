require "test_helper"

class Ifsc::ResultSyncerTest < ActiveSupport::TestCase
  test "syncs seasons from API response" do
    data = {
      "seasons" => [
        {
          "id" => 99,
          "name" => "IFSC World Cup 2026",
          "leagues" => []
        }
      ]
    }

    assert_difference "Season.count", 1 do
      Ifsc::ResultSyncer.sync_seasons(data)
    end

    season = Season.find_by(external_id: 99)
    assert_equal "IFSC World Cup 2026", season.name
    assert_equal 2026, season.year
  end

  test "syncs seasons idempotently" do
    data = {
      "seasons" => [
        {
          "id" => 99,
          "name" => "IFSC World Cup 2026",
          "leagues" => []
        }
      ]
    }

    Ifsc::ResultSyncer.sync_seasons(data)
    assert_no_difference "Season.count" do
      Ifsc::ResultSyncer.sync_seasons(data)
    end
  end

  test "syncs events from season data" do
    data = JSON.parse(File.read(Rails.root.join("test/fixtures/files/ifsc_seasons_response.json")))

    # Use a new external_id to avoid fixture conflicts
    data["seasons"].first["id"] = 99

    Ifsc::ResultSyncer.sync_seasons(data)

    season = Season.find_by(external_id: 99)
    assert_equal 1, season.events.count

    event = season.events.first
    assert_equal "IFSC World Cup Seoul 2025", event.name
    assert_equal "Seoul, KOR", event.location
  end

  test "syncs categories from event results" do
    event = events(:innsbruck_boulder)
    data = {
      "d_cats" => [
        {
          "dcat_id" => 9001,
          "dcat_name" => "Speed - Men",
          "discipline" => "speed",
          "category" => "men",
          "status" => "finished"
        }
      ]
    }

    assert_difference -> { event.categories.count }, 1 do
      Ifsc::ResultSyncer.sync_categories(event, data)
    end

    cat = event.categories.find_by(external_id: 9001)
    assert_equal "Speed - Men", cat.name
    assert_equal "speed", cat.discipline
    assert_equal "male", cat.gender
  end

  test "syncs round results from category data" do
    category = categories(:innsbruck_boulder_men)
    data = JSON.parse(File.read(Rails.root.join("test/fixtures/files/ifsc_category_results_response.json")))

    Ifsc::ResultSyncer.sync_results(category, data)

    assert category.rounds.any?
  end
end
