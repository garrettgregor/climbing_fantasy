require "test_helper"

class RoundTest < ActiveSupport::TestCase
  test "validates presence of name" do
    round = Round.new(category: categories(:innsbruck_boulder_men), round_type: :qualification, status: :pending)
    round.name = nil
    assert_not round.valid?
    assert_includes round.errors[:name], "can't be blank"
  end

  test "round_type enum values" do
    assert_equal %w[qualification round_of_16 quarter_final semi_final small_final final], Round.round_types.keys
  end

  test "status enum values" do
    assert_equal %w[pending in_progress completed], Round.statuses.keys
  end

  test "belongs to category" do
    round = rounds(:innsbruck_boulder_men_qual)
    assert_equal categories(:innsbruck_boulder_men), round.category
  end

  test "has many round_results" do
    round = rounds(:innsbruck_boulder_men_final)
    assert_includes round.round_results, round_results(:fujii_innsbruck_final)
    assert_includes round.round_results, round_results(:narasaki_innsbruck_final)
  end

  test "has many climbs" do
    round = rounds(:innsbruck_boulder_men_final)
    assert_includes round.climbs, climbs(:innsbruck_final_problem_1)
  end
end

# == Schema Information
#
# Table name: rounds
#
#  id                :bigint           not null, primary key
#  name              :string           not null
#  round_type        :string           not null
#  status            :integer          default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  category_id       :bigint           not null
#  external_round_id :integer
#
# Indexes
#
#  index_rounds_on_category_id  (category_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#
