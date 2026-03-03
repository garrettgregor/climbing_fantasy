require "test_helper"

class EventQueryTest < ActiveSupport::TestCase
  test "returns all events with no params" do
    results = EventQuery.call({})
    assert_equal Event.count, results.count
  end

  test "filters by season_id" do
    season = seasons(:season_2025)
    results = EventQuery.call(season_id: season.id)
    assert results.all? { |e| e.season_id == season.id }
    assert_equal Event.where(season_id: season.id).count, results.count
  end

  test "filters by discipline via categories join" do
    results = EventQuery.call(discipline: "boulder")
    assert_not_empty results
    results.each do |event|
      assert event.categories.exists?(discipline: :boulder)
    end
  end

  test "filters by status" do
    results = EventQuery.call(status: "completed")
    assert results.all?(&:completed?)
  end

  test "filters by year via season join" do
    results = EventQuery.call(year: 2025)
    assert results.all? { |e| e.season.year == 2025 }
    assert_not_empty results
  end
end
