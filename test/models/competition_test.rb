require "test_helper"

class CompetitionTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:season)
  should have_many(:categories)

  # Validations
  should validate_presence_of(:name)
  should validate_presence_of(:location)
  should validate_presence_of(:starts_on)
  should validate_presence_of(:ends_on)
  should validate_presence_of(:discipline)
  should validate_presence_of(:status)

  # Enums
  test "discipline enum values" do
    assert_equal %w[boulder lead speed combined boulder_and_lead], Competition.disciplines.keys
  end

  test "status enum values" do
    assert_equal %w[upcoming in_progress completed], Competition.statuses.keys
  end

  test "competition belongs to season" do
    competition = competitions(:innsbruck_boulder)
    assert_equal seasons(:season_2024), competition.season
  end
end
