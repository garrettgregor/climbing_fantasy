require "test_helper"

module Ifsc
  class ResultSyncerTest < ActiveSupport::TestCase
    setup do
      @client = VCR.use_cassette("ifsc_api_client/session") { ApiClient.new }
      @season = Season.find_or_create_by!(source: :ifsc, external_id: 38) do |s|
        s.name = "2026"
        s.year = 2026
      end
      @event = Event.find_or_create_by!(source: :ifsc, external_id: 1491) do |e|
        e.season = @season
        e.name = "Mount Maunganui 2026"
        e.location = "Mount Maunganui, NZ"
        e.starts_on = Date.new(2026, 2, 14)
        e.ends_on = Date.new(2026, 2, 14)
        e.status = :in_progress
        e.sync_state = :needs_results
      end

      # Create only one category with the round we have a cassette for
      @category = Category.find_or_create_by!(event: @event, external_dcat_id: 490) do |c|
        c.name = "SPEED Men"
        c.discipline = :speed
        c.gender = :male
      end
      @round = Round.find_or_create_by!(category: @category, external_round_id: 10468) do |r|
        r.name = "Qualification"
        r.round_type = :qualification
        r.status = :pending
      end
      Route.find_or_create_by!(round: @round, external_route_id: 18663) do |r|
        r.group_label = "a"
        r.route_name = "A"
        r.route_order = 0
      end
      Route.find_or_create_by!(round: @round, external_route_id: 18664) do |r|
        r.group_label = "b"
        r.route_name = "B"
        r.route_order = 1
      end
    end

    test "syncs round results from ranking data" do
      VCR.use_cassette("ifsc_api_client/get_category_round_results_10468") do
        ResultSyncer.call(event: @event, client: @client)
      end

      assert @round.round_results.any?
    end

    test "creates round results with rank and score" do
      VCR.use_cassette("ifsc_api_client/get_category_round_results_10468") do
        ResultSyncer.call(event: @event, client: @client)
      end

      top_result = @round.round_results.find_by(rank: 1)
      assert_not_nil top_result
      assert_equal "5.43", top_result.score_raw
    end

    test "finds or creates athletes from ranking entries" do
      VCR.use_cassette("ifsc_api_client/get_category_round_results_10468") do
        ResultSyncer.call(event: @event, client: @client)
      end

      athlete = Athlete.find_by(source: :ifsc, external_athlete_id: 13915)
      assert_not_nil athlete
      assert_equal "Julian", athlete.first_name
    end

    test "populates flag_url from ranking data" do
      VCR.use_cassette("ifsc_api_client/get_category_round_results_10468") do
        ResultSyncer.call(event: @event, client: @client)
      end

      athlete = Athlete.find_by(source: :ifsc, external_athlete_id: 13915)
      assert_equal "https://d1n1qj9geboqnb.cloudfront.net/flags/NZL.png", athlete.flag_url
    end

    test "updates results_synced_at" do
      VCR.use_cassette("ifsc_api_client/get_category_round_results_10468") do
        ResultSyncer.call(event: @event, client: @client)
      end

      @event.reload
      assert_not_nil @event.results_synced_at
    end

    test "updates round status" do
      VCR.use_cassette("ifsc_api_client/get_category_round_results_10468") do
        ResultSyncer.call(event: @event, client: @client)
      end

      @round.reload
      assert @round.completed?
    end

    test "creates ascents for route results" do
      VCR.use_cassette("ifsc_api_client/get_category_round_results_10468") do
        ResultSyncer.call(event: @event, client: @client)
      end

      top_result = @round.round_results.find_by(rank: 1)
      assert top_result.ascents.any?
    end

    test "is idempotent" do
      2.times do
        VCR.use_cassette("ifsc_api_client/get_category_round_results_10468", allow_playback_repeats: true) do
          ResultSyncer.call(event: @event, client: @client)
        end
      end

      assert_equal 16, @round.round_results.count
    end
  end
end
