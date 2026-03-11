require "test_helper"

module Ifsc
  class EventSyncerTest < ActiveSupport::TestCase
    setup do
      @client = VCR.use_cassette("ifsc_api_client/session") { ApiClient.new }
      @season = Season.find_or_create_by!(external_id: 38) do |s|
        s.name = "2026"
        s.year = 2026
      end
      @event = Event.find_or_create_by!(external_id: 1491) do |e|
        e.season = @season
        e.name = "Mount Maunganui 2026"
        e.location = "Mount Maunganui, NZ"
        e.starts_on = Date.new(2026, 2, 14)
        e.ends_on = Date.new(2026, 2, 14)
        e.status = :completed
        e.sync_state = :pending_sync
      end
    end

    test "syncs categories from event d_cats" do
      VCR.use_cassette("ifsc_api_client/get_event_1491") do
        EventSyncer.call(event: @event, client: @client)
      end

      assert @event.categories.any?
      cat = @event.categories.find_by(external_dcat_id: 490)
      assert_not_nil cat
      assert_equal "SPEED Men", cat.name
      assert_equal "speed", cat.discipline
      assert_equal "male", cat.gender
    end

    test "syncs rounds for each category" do
      VCR.use_cassette("ifsc_api_client/get_event_1491") do
        EventSyncer.call(event: @event, client: @client)
      end

      cat = @event.categories.find_by(external_dcat_id: 490)
      assert cat.rounds.any?

      qual = cat.rounds.find_by(external_round_id: 10468)
      assert_not_nil qual
      assert_equal "Qualification", qual.name
      assert_equal "qualification", qual.round_type
      assert_equal "completed", qual.status
    end

    test "creates routes from API route data" do
      VCR.use_cassette("ifsc_api_client/get_event_1491") do
        EventSyncer.call(event: @event, client: @client)
      end

      cat = @event.categories.find_by(external_dcat_id: 490)
      qual = cat.rounds.find_by(external_round_id: 10468)
      assert qual.routes.any?
    end

    test "marks event as needs_results" do
      VCR.use_cassette("ifsc_api_client/get_event_1491") do
        EventSyncer.call(event: @event, client: @client)
      end

      @event.reload
      assert @event.needs_results?
    end

    test "updates event location from event detail payload" do
      @event.update!(location: "Placeholder")

      VCR.use_cassette("ifsc_api_client/get_event_1491") do
        EventSyncer.call(event: @event, client: @client)
      end

      @event.reload
      assert_equal "Mount Maunganui, New Zealand", @event.location
    end

    test "raises ApiError when event payload is missing location" do
      client = Object.new
      client.define_singleton_method(:get_event) do |_id|
        {
          "location" => nil,
          "infosheet_url" => nil,
          "d_cats" => [],
        }
      end

      error = assert_raises(Ifsc::ApiClient::ApiError) do
        EventSyncer.call(event: @event, client:)
      end
      assert_includes error.message, "missing location"
    end

    test "is idempotent" do
      2.times do
        VCR.use_cassette("ifsc_api_client/get_event_1491") do
          EventSyncer.call(event: @event, client: @client)
        end
      end

      assert_equal 2, @event.categories.count
    end
  end
end
