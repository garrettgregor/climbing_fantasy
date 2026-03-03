require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "validates presence of name" do
    event = Event.new(season: seasons(:season_2025), location: "X", starts_on: Time.zone.today, ends_on: Time.zone.today, status: :upcoming)
    event.name = nil
    assert_not event.valid?
    assert_includes event.errors[:name], "can't be blank"
  end

  test "validates presence of location" do
    event = Event.new(season: seasons(:season_2025), name: "X", starts_on: Time.zone.today, ends_on: Time.zone.today, status: :upcoming)
    event.location = nil
    assert_not event.valid?
    assert_includes event.errors[:location], "can't be blank"
  end

  test "validates presence of starts_on" do
    event = Event.new(season: seasons(:season_2025), name: "X", location: "X", ends_on: Time.zone.today, status: :upcoming)
    event.starts_on = nil
    assert_not event.valid?
    assert_includes event.errors[:starts_on], "can't be blank"
  end

  test "validates presence of ends_on" do
    event = Event.new(season: seasons(:season_2025), name: "X", location: "X", starts_on: Time.zone.today, status: :upcoming)
    event.ends_on = nil
    assert_not event.valid?
    assert_includes event.errors[:ends_on], "can't be blank"
  end

  test "status enum values" do
    assert_equal ["upcoming", "in_progress", "completed"], Event.statuses.keys
  end

  test "sync_state enum values" do
    assert_equal ["pending_sync", "synced", "needs_results"], Event.sync_states.keys
  end

  test "belongs to season" do
    event = events(:keqiao_boulder)
    assert_equal seasons(:season_2025), event.season
  end

  test "has many categories" do
    event = events(:keqiao_boulder)
    assert_includes event.categories, categories(:keqiao_boulder_men)
  end

  test "results_synced_at is nil by default" do
    event = events(:keqiao_boulder)
    assert_nil event.results_synced_at
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
