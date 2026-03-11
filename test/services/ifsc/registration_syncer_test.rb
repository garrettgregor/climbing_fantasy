require "test_helper"

module Ifsc
  class RegistrationSyncerTest < ActiveSupport::TestCase
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
        e.sync_state = :synced
      end

      # Sync event first so categories exist
      VCR.use_cassette("ifsc_api_client/get_event_1491") do
        EventSyncer.call(event: @event, client: @client)
      end
    end

    test "creates athletes from registration data" do
      VCR.use_cassette("ifsc_api_client/get_event_registrations_1491") do
        RegistrationSyncer.call(event: @event, client: @client)
      end

      athlete = Athlete.find_by(external_athlete_id: 16642)
      assert_not_nil athlete
      assert_equal "Christian", athlete.first_name
      assert_equal "WILLIAMS", athlete.last_name
      assert_equal "AUS", athlete.country_code
      assert_equal "male", athlete.gender
    end

    test "enriches athletes with photo_url and flag_url from athlete detail endpoint" do
      VCR.use_cassette("ifsc_api_client/get_event_registrations_1491") do
        RegistrationSyncer.call(event: @event, client: @client)
      end

      athlete = Athlete.find_by(external_athlete_id: 16642)
      assert_not_nil athlete.flag_url, "flag_url should be populated from athlete detail"
      assert_equal "https://d1n1qj9geboqnb.cloudfront.net/flags/AUS.png", athlete.flag_url
      assert_not_nil athlete.photo_url, "photo_url should be populated from athlete detail"
    end

    test "creates category registrations" do
      VCR.use_cassette("ifsc_api_client/get_event_registrations_1491") do
        RegistrationSyncer.call(event: @event, client: @client)
      end

      speed_men = @event.categories.find_by(external_dcat_id: 490)
      assert speed_men.category_registrations.any?
    end

    test "updates registrations_last_checked_at" do
      VCR.use_cassette("ifsc_api_client/get_event_registrations_1491") do
        RegistrationSyncer.call(event: @event, client: @client)
      end

      @event.reload
      assert_not_nil @event.registrations_last_checked_at
    end

    test "is idempotent" do
      2.times do
        VCR.use_cassette("ifsc_api_client/get_event_registrations_1491") do
          RegistrationSyncer.call(event: @event, client: @client)
        end
      end

      athlete = Athlete.find_by(external_athlete_id: 16642)
      assert_equal 1, Athlete.where(external_athlete_id: 16642).count
      assert_equal 1, athlete.category_registrations.joins(:category).where(categories: { event_id: @event.id }).count
    end
  end

  class RegistrationSyncerPendingEventTest < ActiveSupport::TestCase
    # Integration test using real IFSC API data from event 1515
    # (World Climbing Asia Championship Meishan 2026).
    # This event is upcoming (April 8-12, 2026) with 18 registrations still pending
    # (registration deadline: March 24). It has 6 categories (LEAD/SPEED/BOULDER x M/W)
    # and 7 athletes registered in multiple categories.
    #
    # Key status distinction:
    # - Event-level d_cat status: "registration_pending" (category registration still open)
    # - Per-athlete d_cat status in registrations response: nil (not yet confirmed/finalized,
    #   vs "confirmed" or "not attending" on completed events like NSW Oceania 1523)

    setup do
      @client = VCR.use_cassette("ifsc_api_client/session") { ApiClient.new }
      @season = Season.find_or_create_by!(external_id: 38) do |s|
        s.name = "2026"
        s.year = 2026
      end
      @event = Event.find_or_create_by!(external_id: 1515) do |e|
        e.season = @season
        e.name = "World Climbing Asia Championship Meishan 2026"
        e.location = "Meishan, China"
        e.starts_on = Date.new(2026, 4, 8)
        e.ends_on = Date.new(2026, 4, 12)
        e.status = :upcoming
        e.sync_state = :pending_sync
      end

      VCR.use_cassette("ifsc_api_client/get_event_1515") do
        EventSyncer.call(event: @event, client: @client)
      end
    end

    test "syncs categories for a multi-discipline event" do
      assert_equal 6, @event.categories.count

      category_names = @event.categories.pluck(:name).sort
      assert_equal ["BOULDER Men", "BOULDER Women", "LEAD Men", "LEAD Women", "SPEED Men", "SPEED Women"], category_names
    end

    test "creates athletes and registrations from pending registrations" do
      VCR.use_cassette("ifsc_api_client/get_event_registrations_1515") do
        RegistrationSyncer.call(event: @event, client: @client)
      end

      assert_equal 18, @event.reload.athletes.distinct.count
      assert_not_nil @event.registrations_last_checked_at
    end

    test "handles athletes registered in multiple categories" do
      VCR.use_cassette("ifsc_api_client/get_event_registrations_1515") do
        RegistrationSyncer.call(event: @event, client: @client)
      end

      # Luke GOH WEN BIN (id: 3665) is registered in LEAD Men + BOULDER Men
      luke = Athlete.find_by(external_athlete_id: 3665)
      assert_not_nil luke
      event_regs = luke.category_registrations.joins(:category).where(categories: { event_id: @event.id })
      assert_equal 2, event_regs.count

      registered_cats = event_regs.map { |r| r.category.name }.sort
      assert_equal ["BOULDER Men", "LEAD Men"], registered_cats
    end

    test "distributes registrations across all categories" do
      VCR.use_cassette("ifsc_api_client/get_event_registrations_1515") do
        RegistrationSyncer.call(event: @event, client: @client)
      end

      lead_men = @event.categories.find_by(name: "LEAD Men")
      lead_women = @event.categories.find_by(name: "LEAD Women")
      speed_men = @event.categories.find_by(name: "SPEED Men")
      speed_women = @event.categories.find_by(name: "SPEED Women")
      boulder_men = @event.categories.find_by(name: "BOULDER Men")
      boulder_women = @event.categories.find_by(name: "BOULDER Women")

      assert_equal 5, lead_men.category_registrations.count
      assert_equal 3, lead_women.category_registrations.count
      assert_equal 5, speed_men.category_registrations.count
      assert_equal 2, speed_women.category_registrations.count
      assert_equal 5, boulder_men.category_registrations.count
      assert_equal 5, boulder_women.category_registrations.count
    end
  end

  # Stub client that returns canned registration data for a given event.
  # Mirrors the Ifsc::ApiClient#get_event_registrations interface.
  class StubRegistrationClient
    attr_reader :calls

    def initialize(responses)
      @responses = responses
      @calls = []
    end

    def get_event_registrations(event_id)
      @calls << event_id
      @responses.shift || []
    end

    def get_athlete(_id)
      raise Ifsc::ApiClient::ApiError, "stubbed"
    end
  end

  class RegistrationSyncerEmptyResponseTest < ActiveSupport::TestCase
    # Simulates an upcoming event where the IFSC has not published registrations yet.
    # Real example: all 2026 World Climbing Series events (Keqiao, Wujiang, Bern, etc.)
    # return [] from GET /api/v1/events/:id/registrations when queried months in advance.

    setup do
      @event = events(:keqiao_2026)
      @boulder_men = categories(:keqiao_2026_boulder_men)
      @boulder_women = categories(:keqiao_2026_boulder_women)
    end

    test "no registrations creates no athletes or category registrations" do
      client = StubRegistrationClient.new([[]])

      athlete_count = Athlete.count
      reg_count = CategoryRegistration.count

      RegistrationSyncer.call(event: @event, client: client)

      assert_equal athlete_count, Athlete.count
      assert_equal reg_count, CategoryRegistration.count
      assert_equal [@event.external_id], client.calls
    end

    test "still updates registrations_last_checked_at with empty response" do
      client = StubRegistrationClient.new([[]])

      assert_nil @event.registrations_last_checked_at

      RegistrationSyncer.call(event: @event, client: client)

      assert_not_nil @event.reload.registrations_last_checked_at
    end
  end

  class RegistrationSyncerPartialResponseTest < ActiveSupport::TestCase
    # Simulates an event where registrations are trickling in — some categories
    # have athletes registered while others don't yet.
    # Based on real IFSC response shape from GET /api/v1/events/:id/registrations:
    #   [{"athlete_id":16467, "firstname":"Connor", "lastname":"LINEEN",
    #     "name":"LINEEN Connor", "gender":0, "federation":"SCA",
    #     "federation_id":28, "country":"AUS",
    #     "d_cats":[{"id":491, "name":"BOULDER Men", "status":"confirmed"}]}, ...]

    setup do
      @event = events(:keqiao_2026)
      @boulder_men = categories(:keqiao_2026_boulder_men)
      @boulder_women = categories(:keqiao_2026_boulder_women)
    end

    test "creates registrations only for categories with registrants" do
      registrations = [
        {
          "athlete_id" => 99001,
          "firstname" => "Jane",
          "lastname" => "CLIMBER",
          "name" => "CLIMBER Jane",
          "gender" => 1,
          "federation" => "USA",
          "federation_id" => 1,
          "country" => "USA",
          "d_cats" => [{ "id" => 7, "name" => "BOULDER Women", "status" => "confirmed" }],
        },
      ]
      client = StubRegistrationClient.new([registrations])

      RegistrationSyncer.call(event: @event, client: client)

      athlete = Athlete.find_by(external_athlete_id: 99001)
      assert_not_nil athlete
      assert_equal "Jane", athlete.first_name
      assert_equal "CLIMBER", athlete.last_name
      assert_equal "female", athlete.gender

      assert_equal 1, @boulder_women.category_registrations.count
      assert_equal 0, @boulder_men.category_registrations.count
    end

    test "skips d_cats that do not match any category on the event" do
      registrations = [
        {
          "athlete_id" => 99002,
          "firstname" => "Ghost",
          "lastname" => "CLIMBER",
          "name" => "CLIMBER Ghost",
          "gender" => 0,
          "federation" => "AUS",
          "federation_id" => 28,
          "country" => "AUS",
          "d_cats" => [{ "id" => 999, "name" => "LEAD Men", "status" => "confirmed" }],
        },
      ]
      client = StubRegistrationClient.new([registrations])

      RegistrationSyncer.call(event: @event, client: client)

      athlete = Athlete.find_by(external_athlete_id: 99002)
      assert_not_nil athlete, "Athlete is still created even if no category matches"
      assert_equal 0, athlete.category_registrations.count
    end

    test "re-syncing picks up newly added registrations" do
      first_batch = [
        {
          "athlete_id" => 99003,
          "firstname" => "Early",
          "lastname" => "BIRD",
          "name" => "BIRD Early",
          "gender" => 1,
          "federation" => "NOR",
          "federation_id" => 2,
          "country" => "NOR",
          "d_cats" => [{ "id" => 7, "name" => "BOULDER Women", "status" => "confirmed" }],
        },
      ]
      second_batch = first_batch + [
        {
          "athlete_id" => 99004,
          "firstname" => "Late",
          "lastname" => "ENTRY",
          "name" => "ENTRY Late",
          "gender" => 1,
          "federation" => "SWE",
          "federation_id" => 3,
          "country" => "SWE",
          "d_cats" => [{ "id" => 7, "name" => "BOULDER Women", "status" => "confirmed" }],
        },
      ]

      client = StubRegistrationClient.new([first_batch, second_batch])
      RegistrationSyncer.call(event: @event, client: client)

      assert_equal 1, @boulder_women.category_registrations.count
      first_checked_at = @event.reload.registrations_last_checked_at

      RegistrationSyncer.call(event: @event, client: client)

      assert_equal 2, @boulder_women.category_registrations.count
      assert_operator @event.reload.registrations_last_checked_at, :>, first_checked_at
    end
  end

  class RegistrationSyncerFullResponseTest < ActiveSupport::TestCase
    # Simulates a fully-registered event with athletes across all categories.
    # Based on real data: NSW Oceania 2026 (event 1523) returned 97 registrations
    # across BOULDER Men (d_cat 491) and BOULDER Women (d_cat 511), with statuses
    # "confirmed" and "not attending". Wujiang 2025 (event 1406) had 216 registrations
    # across LEAD + SPEED with 1 athlete (Chi-Fung AU) in multiple d_cats.

    setup do
      @event = events(:keqiao_2026)
      @boulder_men = categories(:keqiao_2026_boulder_men)
      @boulder_women = categories(:keqiao_2026_boulder_women)
    end

    test "populates all categories and tracks registration count per category" do
      registrations = [
        {
          "athlete_id" => 99010,
          "firstname" => "John",
          "lastname" => "BOULDER",
          "name" => "BOULDER John",
          "gender" => 0,
          "federation" => "GBR",
          "federation_id" => 4,
          "country" => "GBR",
          "d_cats" => [{ "id" => 3, "name" => "BOULDER Men", "status" => "confirmed" }],
        },
        {
          "athlete_id" => 99011,
          "firstname" => "Alex",
          "lastname" => "STONE",
          "name" => "STONE Alex",
          "gender" => 0,
          "federation" => "FRA",
          "federation_id" => 5,
          "country" => "FRA",
          "d_cats" => [{ "id" => 3, "name" => "BOULDER Men", "status" => "confirmed" }],
        },
        {
          "athlete_id" => 99012,
          "firstname" => "Maria",
          "lastname" => "SUMMIT",
          "name" => "SUMMIT Maria",
          "gender" => 1,
          "federation" => "ESP",
          "federation_id" => 6,
          "country" => "ESP",
          "d_cats" => [{ "id" => 7, "name" => "BOULDER Women", "status" => "confirmed" }],
        },
      ]
      client = StubRegistrationClient.new([registrations])

      RegistrationSyncer.call(event: @event, client: client)

      assert_equal 2, @boulder_men.category_registrations.count
      assert_equal 1, @boulder_women.category_registrations.count
      assert_equal 3, @event.reload.athletes.count
      assert_not_nil @event.registrations_last_checked_at
    end

    test "includes athletes with not_attending status" do
      # Real API data shows "not attending" athletes are returned in the registrations
      # list (e.g., Luke STOCK in NSW Oceania 1523). The syncer currently creates
      # registrations for all athletes regardless of status.
      registrations = [
        {
          "athlete_id" => 99013,
          "firstname" => "Active",
          "lastname" => "CLIMBER",
          "name" => "CLIMBER Active",
          "gender" => 0,
          "federation" => "AUS",
          "federation_id" => 28,
          "country" => "AUS",
          "d_cats" => [{ "id" => 3, "name" => "BOULDER Men", "status" => "confirmed" }],
        },
        {
          "athlete_id" => 99014,
          "firstname" => "Luke",
          "lastname" => "WITHDRAWN",
          "name" => "WITHDRAWN Luke",
          "gender" => 0,
          "federation" => "NZL",
          "federation_id" => 53,
          "country" => "NZL",
          "d_cats" => [{ "id" => 3, "name" => "BOULDER Men", "status" => "not attending" }],
        },
      ]
      client = StubRegistrationClient.new([registrations])

      RegistrationSyncer.call(event: @event, client: client)

      # Both athletes get registrations — syncer does not filter by d_cat status
      assert_equal 2, @boulder_men.category_registrations.count
      assert_includes @boulder_men.athletes.pluck(:external_athlete_id), 99013
      assert_includes @boulder_men.athletes.pluck(:external_athlete_id), 99014
    end

    test "athlete registered in multiple d_cats gets a registration in each" do
      # Real example: Chi-Fung AU (Wujiang 2025) was registered in both LEAD Men
      # and SPEED Men via a single registration entry with multiple d_cats.
      # Here we simulate with BOULDER Men + BOULDER Women categories available.
      registrations = [
        {
          "athlete_id" => 99015,
          "firstname" => "Multi",
          "lastname" => "DISCIPLINE",
          "name" => "DISCIPLINE Multi",
          "gender" => 0,
          "federation" => "HKG",
          "federation_id" => 10,
          "country" => "HKG",
          "d_cats" => [
            { "id" => 3, "name" => "BOULDER Men", "status" => "confirmed" },
            { "id" => 7, "name" => "BOULDER Women", "status" => "confirmed" },
          ],
        },
      ]
      client = StubRegistrationClient.new([registrations])

      RegistrationSyncer.call(event: @event, client: client)

      athlete = Athlete.find_by(external_athlete_id: 99015)
      assert_equal 2, athlete.category_registrations.joins(:category).where(categories: { event_id: @event.id }).count
      assert_includes @boulder_men.athletes, athlete
      assert_includes @boulder_women.athletes, athlete
    end
  end
end
