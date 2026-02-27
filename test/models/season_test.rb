require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  test "validates presence of name" do
    season = Season.new(year: 2024)
    assert_not season.valid?
    assert_includes season.errors[:name], "can't be blank"
  end

  test "validates presence of year" do
    season = Season.new(name: "Test Season")
    assert_not season.valid?
    assert_includes season.errors[:year], "can't be blank"
  end

  test "validates year is an integer" do
    season = Season.new(name: "Test", year: 20.5)
    assert_not season.valid?
    assert_includes season.errors[:year], "must be an integer"
  end

  test "has many events" do
    season = seasons(:season_2024)
    assert_includes season.events, events(:innsbruck_boulder)
    assert_includes season.events, events(:chamonix_lead)
  end

  test "season has expected attributes" do
    season = seasons(:season_2024)
    assert_equal "IFSC World Cup 2024", season.name
    assert_equal 2024, season.year
  end
end

# == Schema Information
#
# Table name: seasons
#
#  id          :bigint           not null, primary key
#  name        :string
#  year        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  external_id :integer
#
