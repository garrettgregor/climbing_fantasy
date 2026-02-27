class Season < ApplicationRecord
  has_many :events, dependent: :destroy

  validates :name, presence: true
  validates :year, presence: true, numericality: { only_integer: true }
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
