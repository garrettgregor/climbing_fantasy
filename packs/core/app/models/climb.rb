class Climb < ApplicationRecord
  belongs_to :round
  has_many :climb_results, dependent: :destroy

  enum :group_label, { a: "A", b: "B" }, prefix: :group

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
end

# == Schema Information
#
# Table name: climbs
#
#  id          :bigint           not null, primary key
#  group_label :string
#  number      :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  round_id    :bigint           not null
#
# Indexes
#
#  index_climbs_on_round_id                             (round_id)
#  index_climbs_on_round_id_and_group_label_and_number  (round_id,group_label,number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (round_id => rounds.id)
#
