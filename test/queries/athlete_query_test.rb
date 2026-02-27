require "test_helper"

class AthleteQueryTest < ActiveSupport::TestCase
  test "returns all athletes with no params" do
    results = AthleteQuery.call({})
    assert_equal Athlete.count, results.count
  end

  test "searches first_name with q param" do
    results = AthleteQuery.call(q: "Janja")
    assert results.any? { |a| a.first_name == "Janja" }
  end

  test "searches last_name with q param" do
    results = AthleteQuery.call(q: "Fujii")
    assert results.any? { |a| a.last_name == "Fujii" }
  end

  test "filters by country_code" do
    results = AthleteQuery.call(country: "JPN")
    assert results.all? { |a| a.country_code == "JPN" }
    assert_not_empty results
  end
end
