module Ifsc
  class ResultSyncer
    class << self
      def call(event:, client: ApiClient.new)
        new(event:, client:).call
      end
    end

    def initialize(event:, client:)
      @event = event
      @client = client
    end

    def call
      rounds = @event.categories.includes(rounds: :climbs).flat_map(&:rounds)

      rounds.each { |round| sync_round_results(round) }

      @event.update!(results_synced_at: Time.current)
      finalize_event_status if all_rounds_completed?
    end

    private

    def sync_round_results(round)
      return unless round.external_round_id

      data = @client.get_category_round_results(round.external_round_id)

      round.update!(status: map_round_status(data["status"]))

      data["ranking"]&.each { |entry| sync_ranking_entry(round, entry, data) }
    end

    def sync_ranking_entry(round, entry, data)
      athlete = find_or_create_athlete(entry)

      round_result = RoundResult.find_or_initialize_by(round:, athlete:)
      round_result.update!(
        rank: entry["rank"],
        score_raw: entry["score"],
        **aggregate_ascents(entry["ascents"], round.category.discipline),
      )

      sync_climb_results(round, round_result, entry["ascents"])
    end

    def sync_climb_results(round, round_result, ascents)
      return unless ascents

      ascents.each do |ascent|
        climb = round.climbs.find_by(number: ascent["route_id"])
        next unless climb

        climb_result = ClimbResult.find_or_initialize_by(round_result:, climb:)
        update_climb_result(climb_result, ascent, round.category.discipline)
        climb_result.save!
      end
    end

    def update_climb_result(climb_result, ascent, discipline)
      case discipline
      when "speed"
        climb_result.assign_attributes(
          time: ascent["time_ms"]&.then { |ms| ms / 1000.0 },
          top_attempts: ascent["dns"] || ascent["dnf"] ? 0 : 1,
          zone_attempts: 0,
        )
      when "lead"
        climb_result.assign_attributes(
          height: ascent["score"]&.to_d,
          plus: ascent["plus"] || false,
          top_attempts: ascent["top"] ? 1 : 0,
          zone_attempts: 0,
        )
      else
        climb_result.assign_attributes(
          top_attempts: ascent["top"] ? 1 : (ascent["attempts"]&.to_i || 0),
          zone_attempts: ascent["zone"] ? 1 : (ascent["attempts"]&.to_i || 0),
        )
      end
    end

    def aggregate_ascents(ascents, discipline)
      return {} unless ascents

      case discipline
      when "speed"
        best = ascents.reject { |a| a["dnf"] || a["dns"] }.min_by { |a| a["time_ms"].to_i }
        { speed_time: best ? best["time_ms"] / 1000.0 : nil }
      when "lead"
        { lead_height: ascents.first&.dig("score")&.to_d }
      else
        {}
      end
    end

    def find_or_create_athlete(entry)
      athlete = Athlete.find_or_initialize_by(external_athlete_id: entry["athlete_id"])
      athlete.update!(
        first_name: entry["firstname"],
        last_name: entry["lastname"],
        country_code: entry["country"],
        gender: :male,
      ) if athlete.new_record?
      athlete
    end

    def all_rounds_completed?
      @event.rounds.reload.all?(&:completed?)
    end

    def finalize_event_status
      @event.update!(status: :completed, sync_state: :synced)
    end

    def map_round_status(status)
      case status.to_s
      when "finished" then :completed
      when "active" then :in_progress
      else :pending
      end
    end
  end
end
