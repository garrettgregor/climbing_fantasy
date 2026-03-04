require "test_helper"

class ClimbResultTest < ActiveSupport::TestCase
  test "topped? is true when top_attempts is greater than zero" do
    assert climb_results(:anraku_keqiao_p1).topped?
  end

  test "topped? is false when top_attempts is zero" do
    assert_not climb_results(:thomas_nsw_p2).topped?
  end

  test "zoned? is true when zone_attempts is greater than zero" do
    assert climb_results(:anraku_keqiao_p1).zoned?
  end

  test "zoned? is false when zone_attempts is zero" do
    assert_not climb_results(:thomas_nsw_p2).zoned?
  end

  test "high_zoned? is true when high_zone_attempts is greater than zero" do
    climb_result = ClimbResult.new(top_attempts: 0, zone_attempts: 0, high_zone_attempts: 1)
    assert climb_result.high_zoned?
  end

  test "high_zoned? is false when high_zone_attempts is nil" do
    climb_result = ClimbResult.new(top_attempts: 0, zone_attempts: 0, high_zone_attempts: nil)
    assert_not climb_result.high_zoned?
  end

  test "low_zone_attempts aliases zone_attempts" do
    climb_result = climb_results(:anraku_keqiao_p2)
    assert_equal climb_result.zone_attempts, climb_result.low_zone_attempts
  end
end

# == Schema Information
#
# Table name: climb_results
#
#  id                 :bigint           not null, primary key
#  disqualification   :string
#  height             :decimal(5, 2)
#  high_zone_attempts :integer
#  plus               :boolean
#  rank               :integer
#  score_raw          :string
#  time               :decimal(7, 3)
#  top_attempts       :integer          default(0), not null
#  zone_attempts      :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  climb_id           :bigint           not null
#  round_result_id    :bigint           not null
#
# Indexes
#
#  index_climb_results_on_climb_id                      (climb_id)
#  index_climb_results_on_round_result_id               (round_result_id)
#  index_climb_results_on_round_result_id_and_climb_id  (round_result_id,climb_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (climb_id => climbs.id)
#  fk_rails_...  (round_result_id => round_results.id)
#
