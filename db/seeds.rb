# Create super_admin account
admin = AdminUser.find_or_initialize_by(email: "admin@climbingfantasy.com")
admin.assign_attributes(
  password: "password123456",
  password_confirmation: "password123456",
  role: :super_admin,
)
admin.save!

Rails.logger.info("Seeded AdminUser: admin@climbingfantasy.com (super_admin)")

unless Rails.env.production?
  fixture_path = Rails.root.join("test/fixtures")

  load_fixture = lambda do |filename|
    records = YAML.safe_load(
      ERB.new(File.read(fixture_path.join(filename))).result,
      permitted_classes: [Date, Time],
      aliases: true,
    ) || {}

    records.reject { |key, _| key.start_with?("#") || key.include?("Schema") }
  end

  fetch_record = lambda do |records, label, fixture_name|
    records.fetch(label)
  rescue KeyError
    raise KeyError, "Missing fixture reference '#{label}' in #{fixture_name}"
  end

  upsert = lambda do |model_class, lookup, attributes|
    record = model_class.find_or_initialize_by(lookup)
    record.assign_attributes(attributes)
    record.save!
    record
  end

  # --- Seasons ---
  seasons_data = load_fixture.call("seasons.yml")
  seasons = {}
  seasons_data.each do |key, attrs|
    seasons[key] = upsert.call(
      Season,
      { external_id: attrs["external_id"] },
      { name: attrs["name"], year: attrs["year"] },
    )
  end
  Rails.logger.info("Seeded #{seasons.size} seasons")

  # --- Athletes ---
  athletes_data = load_fixture.call("athletes.yml")
  athletes = {}
  athletes_data.each do |key, attrs|
    athletes[key] = upsert.call(
      Athlete,
      { external_athlete_id: attrs["external_athlete_id"] },
      {
        first_name: attrs["first_name"],
        last_name: attrs["last_name"],
        country_code: attrs["country_code"],
        gender: attrs["gender"],
        height: attrs["height"],
        arm_span: attrs["arm_span"],
        birthday: attrs["birthday"],
      },
    )
  end
  Rails.logger.info("Seeded #{athletes.size} athletes")

  # --- Events ---
  events_data = load_fixture.call("events.yml")
  events = {}
  events_data.each do |key, attrs|
    season = fetch_record.call(seasons, attrs["season"], "events.yml")
    events[key] = upsert.call(
      Event,
      { external_id: attrs["external_id"] },
      {
        season:,
        name: attrs["name"],
        location: attrs["location"],
        starts_on: attrs["starts_on"],
        ends_on: attrs["ends_on"],
        status: attrs["status"],
      },
    )
  end
  Rails.logger.info("Seeded #{events.size} events")

  # --- Categories ---
  categories_data = load_fixture.call("categories.yml")
  categories = {}
  categories_data.each do |key, attrs|
    event = fetch_record.call(events, attrs["event"], "categories.yml")
    categories[key] = upsert.call(
      Category,
      { event:, external_dcat_id: attrs["external_dcat_id"] },
      {
        name: attrs["name"],
        discipline: attrs["discipline"],
        gender: attrs["gender"],
      },
    )
  end
  Rails.logger.info("Seeded #{categories.size} categories")

  # --- Rounds ---
  rounds_data = load_fixture.call("rounds.yml")
  rounds = {}
  rounds_data.each do |key, attrs|
    category = fetch_record.call(categories, attrs["category"], "rounds.yml")
    rounds[key] = upsert.call(
      Round,
      { category:, external_round_id: attrs["external_round_id"] },
      {
        name: attrs["name"],
        round_type: attrs["round_type"],
        status: attrs["status"],
      },
    )
  end
  Rails.logger.info("Seeded #{rounds.size} rounds")

  # --- Round Results ---
  round_results_data = load_fixture.call("round_results.yml")
  round_results = {}
  round_results_data.each do |key, attrs|
    round = fetch_record.call(rounds, attrs["round"], "round_results.yml")
    athlete = fetch_record.call(athletes, attrs["athlete"], "round_results.yml")
    round_results[key] = upsert.call(
      RoundResult,
      { round:, athlete: },
      {
        rank: attrs["rank"],
        score_raw: attrs["score_raw"],
        tops: attrs["tops"],
        zones: attrs["zones"],
        top_attempts: attrs["top_attempts"],
        zone_attempts: attrs["zone_attempts"],
        lead_height: attrs["lead_height"],
        lead_plus: attrs["lead_plus"],
        speed_time: attrs["speed_time"],
        speed_eliminated_stage: attrs["speed_eliminated_stage"],
      },
    )
  end
  Rails.logger.info("Seeded #{round_results.size} round results")

  # --- Climbs ---
  climbs_data = load_fixture.call("climbs.yml")
  climbs = {}
  climbs_data.each do |key, attrs|
    round = fetch_record.call(rounds, attrs["round"], "climbs.yml")
    climbs[key] = upsert.call(Climb, { round:, number: attrs["number"] }, {})
  end
  Rails.logger.info("Seeded #{climbs.size} climbs")

  # --- Climb Results ---
  climb_results_data = load_fixture.call("climb_results.yml")
  climb_results_data.each do |_key, attrs|
    round_result = fetch_record.call(round_results, attrs["round_result"], "climb_results.yml")
    climb = fetch_record.call(climbs, attrs["climb"], "climb_results.yml")
    upsert.call(
      ClimbResult,
      { round_result:, climb: },
      {
        top_attempts: attrs["top_attempts"],
        zone_attempts: attrs["zone_attempts"],
      },
    )
  end
  Rails.logger.info("Seeded #{climb_results_data.size} climb results")

  # --- Category Registrations ---
  registrations_data = load_fixture.call("category_registrations.yml")
  registrations_data.each do |_key, attrs|
    category = fetch_record.call(categories, attrs["category"], "category_registrations.yml")
    athlete = fetch_record.call(athletes, attrs["athlete"], "category_registrations.yml")
    upsert.call(CategoryRegistration, { category:, athlete: }, {})
  end
  Rails.logger.info("Seeded #{registrations_data.size} category registrations")
end
