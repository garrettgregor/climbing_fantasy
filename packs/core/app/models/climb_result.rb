class ClimbResult < ApplicationRecord
  belongs_to :round_result
  belongs_to :climb

  validates :round_result_id, uniqueness: { scope: :climb_id }
  validates :top_attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :zone_attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

# == Schema Information
#
# Table name: climb_results
#
#  id               :bigint           not null, primary key
#  disqualification :string
#  height           :decimal(5, 2)
#  plus             :boolean
#  rank             :integer
#  score_raw        :string
#  time             :decimal(7, 3)
#  top_attempts     :integer          default(0), not null
#  zone_attempts    :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  climb_id         :bigint           not null
#  round_result_id  :bigint           not null
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
