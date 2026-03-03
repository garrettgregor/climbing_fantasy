class Event < ApplicationRecord
  belongs_to :season
  has_many :categories, dependent: :destroy
  has_many :category_registrations, through: :categories
  has_many :athletes, through: :category_registrations
  has_many :rounds, through: :categories

  enum :status, { upcoming: 0, in_progress: 1, completed: 2 }
  enum :sync_state, { pending_sync: 0, synced: 1, needs_results: 2 }

  validates :name, presence: true
  validates :location, presence: true
  validates :starts_on, presence: true
  validates :ends_on, presence: true
  validates :status, presence: true

  class << self
    def ransackable_attributes(_auth_object = nil)
      [
        "name",
        "location",
        "status",
        "sync_state",
        "starts_on",
        "ends_on",
        "results_synced_at",
        "results_last_synced_at",
        "season_id",
      ]
    end

    def ransackable_associations(_auth_object = nil)
      ["season", "categories", "category_registrations", "athletes", "rounds"]
    end
  end
end

# == Schema Information
#
# Table name: events
#
#  id                           :bigint           not null, primary key
#  ends_on                      :date             not null
#  info_sheet_url               :string
#  location                     :string           not null
#  name                         :string           not null
#  registrations_last_checked_at :datetime
#  results_last_synced_at       :datetime
#  results_synced_at            :datetime
#  starts_on                    :date             not null
#  status                       :integer          default("upcoming"), not null
#  sync_state                   :integer          default("pending_sync"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  external_id                  :integer
#  season_id                    :bigint           not null
#
# Indexes
#
#  index_events_on_season_id   (season_id)
#  index_events_on_sync_state  (sync_state)
#
# Foreign Keys
#
#  fk_rails_...  (season_id => seasons.id)
#
