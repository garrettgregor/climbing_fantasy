class Event < ApplicationRecord
  belongs_to :season
  has_many :categories, dependent: :destroy

  enum :discipline, { boulder: 0, lead: 1, speed: 2, combined: 3, boulder_and_lead: 4 }
  enum :status, { upcoming: 0, in_progress: 1, completed: 2 }

  validates :name, presence: true
  validates :location, presence: true
  validates :starts_on, presence: true
  validates :ends_on, presence: true
  validates :discipline, presence: true
  validates :status, presence: true

  class << self
    def ransackable_attributes(_auth_object = nil)
      ["name", "location", "discipline", "status", "starts_on", "ends_on", "results_synced_at", "season_id"]
    end

    def ransackable_associations(_auth_object = nil)
      ["season", "categories"]
    end
  end
end

# == Schema Information
#
# Table name: events
#
#  id                :bigint           not null, primary key
#  discipline        :integer          not null
#  ends_on           :date             not null
#  location          :string           not null
#  name              :string           not null
#  results_synced_at :datetime
#  starts_on         :date             not null
#  status            :integer          default("upcoming"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  external_id       :integer
#  season_id         :bigint           not null
#
# Indexes
#
#  index_events_on_season_id  (season_id)
#
# Foreign Keys
#
#  fk_rails_...  (season_id => seasons.id)
#
