require "test_helper"

class RoundResultTest < ActiveSupport::TestCase
  # Associations
  should belong_to(:round)
  should belong_to(:athlete)

  # Validations
  should validate_numericality_of(:rank).only_integer.allow_nil
  should validate_numericality_of(:tops).only_integer.allow_nil
  should validate_numericality_of(:zones).only_integer.allow_nil
  should validate_numericality_of(:top_attempts).only_integer.allow_nil
  should validate_numericality_of(:zone_attempts).only_integer.allow_nil

  test "unique athlete per round" do
    existing = round_results(:fujii_innsbruck_final)
    duplicate = RoundResult.new(
      round: existing.round,
      athlete: existing.athlete,
      rank: 2,
      score_raw: "duplicate"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:athlete_id], "has already been taken"
  end

  test "boulder result attributes" do
    result = round_results(:fujii_innsbruck_final)
    assert_equal 1, result.rank
    assert_equal 4, result.tops
    assert_equal 4, result.zones
    assert_equal 5, result.top_attempts
    assert_equal 4, result.zone_attempts
  end

  test "lead result attributes" do
    result = round_results(:garnbret_chamonix_final)
    assert_in_delta 42.5, result.lead_height
    assert result.lead_plus
  end

  test "speed result attributes" do
    result = round_results(:speed_result)
    assert_in_delta 6.53, result.speed_time
    assert_equal "quarter_final", result.speed_eliminated_stage
  end
end
