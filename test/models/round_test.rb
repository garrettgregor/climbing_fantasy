require "test_helper"

class RoundTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:category)
  should have_many(:round_results)

  # Validations
  should validate_presence_of(:name)
  should validate_presence_of(:round_type)
  should validate_presence_of(:status)

  # Enums
  test "round_type enum values" do
    assert_equal %w[qualification semi_final final], Round.round_types.keys
  end

  test "status enum values" do
    assert_equal %w[pending in_progress completed], Round.statuses.keys
  end

  test "round belongs to category" do
    round = rounds(:innsbruck_boulder_men_qual)
    assert_equal categories(:innsbruck_boulder_men), round.category
  end
end
