require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  # Associations
  should have_many(:competitions)

  # Validations
  should validate_presence_of(:name)
  should validate_presence_of(:year)
  should validate_numericality_of(:year).only_integer

  test "season has expected attributes" do
    season = seasons(:season_2024)
    assert_equal "IFSC World Cup 2024", season.name
    assert_equal 2024, season.year
  end
end
