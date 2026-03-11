module Ifsc
  class SeasonSyncer
    CURRENT_SEASON_IDS = [37, 38].freeze
    TARGET_LEAGUE_PATTERN = /world cup/i
    LOCATION_PREFIX_PATTERNS = [
      /\AWorld Climbing Series\s+/i,
      /\AWorld Climbing Oceania Series\s+/i,
      /\AIFSC Climbing World Cup\s+/i,
      /\AIFSC World Cup\s+/i,
      /\AIFSC World Championships\s+/i,
    ].freeze

    class << self
      def call(client: ApiClient.new, season_ids: CURRENT_SEASON_IDS)
        new(client:, season_ids:).call
      end
    end

    def initialize(client:, season_ids: CURRENT_SEASON_IDS)
      @client = client
      @season_ids = season_ids
    end

    def call
      @season_ids.each { |id| sync_season(id) }
    end

    private

    def sync_season(season_id)
      data = @client.get_season(season_id)

      season = Season.find_or_initialize_by(source: :ifsc, external_id: season_id)
      season.update!(
        name: data["name"],
        year: data["name"].to_i,
      )

      league = data["leagues"]&.find { |l| l["name"].match?(TARGET_LEAGUE_PATTERN) }

      unless league
        Rails.logger.warn("SeasonSyncer: No league matching #{TARGET_LEAGUE_PATTERN.inspect} for season #{season_id}")
        return
      end

      league_id = league["url"].split("/").last.to_i
      league_data = @client.get_season_league(league_id)

      league_data["events"].each { |event_data| sync_event(season, event_data) }
    end

    def sync_event(season, event_data)
      event = Event.find_or_initialize_by(source: :ifsc, external_id: event_data["event_id"])
      attrs = {
        season:,
        name: event_data["event"],
        country_code: event_data["country"],
        starts_on: Date.parse(event_data["local_start_date"]),
        ends_on: Date.parse(event_data["local_end_date"]),
        starts_at: Time.zone.parse(event_data["starts_at"]),
        ends_at: Time.zone.parse(event_data["ends_at"]),
        timezone_name: event_data.dig("timezone", "value"),
        status: infer_status(event_data["starts_at"], event_data["ends_at"]),
      }

      attrs[:location] = if event.new_record?
        event_data["location"] || parse_location_from_event_name(event_data["event"]) || event_data["event"]
      else
        event.location
      end

      event.assign_attributes(attrs)
      event.sync_state = :pending_sync if event.new_record?
      event.save!
    end

    def parse_location_from_event_name(event_name)
      location = event_name.to_s.strip
      return if location.blank?

      location = location.sub(/\s+\d{4}\z/, "")
      LOCATION_PREFIX_PATTERNS.each { |pattern| location = location.sub(pattern, "") }

      location = location.strip
      location.presence
    end

    def infer_status(starts_at, ends_at)
      now = Time.current
      start_time = Time.zone.parse(starts_at)
      end_time = Time.zone.parse(ends_at)

      if now < start_time
        :upcoming
      elsif now > end_time
        :completed
      else
        :in_progress
      end
    end
  end
end
