require "test_helper"

class RoundResultTest < ActiveSupport::TestCase
  test "validates rank is integer when present" do
    result = RoundResult.new(round: rounds(:keqiao_boulder_men_final), athlete: athletes(:annie_sanders))
    result.rank = 1.5
    assert_not result.valid?
    assert_includes result.errors[:rank], "must be an integer"
  end

  test "allows nil rank" do
    result = RoundResult.new(round: rounds(:wujiang_lead_women_final), athlete: athletes(:tomoa_narasaki), rank: nil)
    assert result.valid?
  end

  test "validates boulder integer fields" do
    result = RoundResult.new(round: rounds(:keqiao_boulder_men_final), athlete: athletes(:annie_sanders))
    result.tops = 1.5
    assert_not result.valid?
    assert_includes result.errors[:tops], "must be an integer"
  end

  test "unique athlete per round" do
    existing = round_results(:anraku_keqiao_boulder_final)
    duplicate = RoundResult.new(
      round: existing.round,
      athlete: existing.athlete,
      rank: 2,
      score_raw: "duplicate",
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:athlete_id], "has already been taken"
  end

  test "belongs to round" do
    result = round_results(:anraku_keqiao_boulder_final)
    assert_equal rounds(:keqiao_boulder_men_final), result.round
  end

  test "belongs to athlete" do
    result = round_results(:anraku_keqiao_boulder_final)
    assert_equal athletes(:sorato_anraku), result.athlete
  end

  test "boulder result attributes" do
    result = round_results(:anraku_keqiao_boulder_final)
    assert_equal 1, result.rank
    assert_equal 4, result.tops
    assert_equal 4, result.zones
    assert_equal 7, result.top_attempts
    assert_equal 4, result.zone_attempts
  end

  test "lead result attributes" do
    result = round_results(:anraku_wujiang_lead_final)
    assert_in_delta 50.0, result.lead_height
    assert_not result.lead_plus
  end

  test "speed result attributes" do
    result = round_results(:katibin_wujiang_speed_final)
    assert_in_delta 4.75, result.speed_time
    assert_equal "semi_final", result.speed_eliminated_stage
  end
end

# == Schema Information
#
# Table name: round_results
#
#  id                     :bigint           not null, primary key
#  boulder_points         :decimal(, )
#  group_label            :string
#  high_zone_attempts     :integer
#  high_zones             :integer
#  lead_height            :decimal(, )
#  lead_plus              :boolean          default(FALSE)
#  rank                   :integer
#  score_raw              :string
#  speed_eliminated_stage :string
#  speed_time             :decimal(, )
#  top_attempts           :integer
#  tops                   :integer
#  zone_attempts          :integer
#  zones                  :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  athlete_id             :bigint           not null
#  round_id               :bigint           not null
#
# Indexes
#
#  index_round_results_on_athlete_id               (athlete_id)
#  index_round_results_on_round_id                 (round_id)
#  index_round_results_on_round_id_and_athlete_id  (round_id,athlete_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (athlete_id => athletes.id)
#  fk_rails_...  (round_id => rounds.id)
#
