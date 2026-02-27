class Athlete < ApplicationRecord
  has_many :round_results, dependent: :destroy

  enum :gender, { male: 0, female: 1, non_binary: 2, other: 3 }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :country_code, presence: true, length: { maximum: 3 }
  validates :gender, presence: true
  validates :external_athlete_id, uniqueness: true, allow_nil: true
  validates :height, :arm_span, numericality: { greater_than: 0 }, allow_nil: true

  class << self
    def ransackable_attributes(_auth_object = nil)
      ["first_name", "last_name", "country_code", "gender"]
    end
  end
end

# == Schema Information
#
# Table name: athletes
#
#  id                  :bigint           not null, primary key
#  arm_span            :float
#  birthday            :date
#  country_code        :string(3)        not null
#  first_name          :string           not null
#  gender              :integer          not null
#  height              :float
#  last_name           :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  external_athlete_id :integer
#
# Indexes
#
#  index_athletes_on_external_athlete_id  (external_athlete_id) UNIQUE
#
