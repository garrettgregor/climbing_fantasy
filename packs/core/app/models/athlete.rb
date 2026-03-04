class Athlete < ApplicationRecord
  has_many :round_results, dependent: :destroy
  has_many :category_registrations, dependent: :destroy
  has_many :rounds, through: :round_results
  has_many :categories, through: :category_registrations
  has_many :climb_results, through: :round_results

  enum :gender, { male: 0, female: 1 }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :country_code, presence: true, length: { maximum: 3 }
  validates :gender, presence: true
  validates :external_athlete_id, uniqueness: true, allow_nil: true

  class << self
    def ransackable_attributes(_auth_object = nil)
      [
        "first_name",
        "last_name",
        "country_code",
        "gender",
      ]
    end
  end
end

# == Schema Information
#
# Table name: athletes
#
#  id                  :bigint           not null, primary key
#  country_code        :string(3)        not null
#  first_name          :string           not null
#  gender              :integer          not null
#  last_name           :string           not null
#  photo_url           :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  external_athlete_id :integer
#
# Indexes
#
#  index_athletes_on_external_athlete_id  (external_athlete_id) UNIQUE
#
