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
      rounds = @event.categories.includes(rounds: :routes).flat_map(&:rounds)

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
        start_order: entry["start_order"],
        bib: entry["bib"],
        starting_group: entry["starting_group"],
        group_rank: entry["group_rank"],
        active: entry["active"],
        under_appeal: entry["under_appeal"],
        **aggregate_ascents(entry["ascents"], round.category.discipline),
      )

      sync_ascents(round, round_result, entry["ascents"])
    end

    def sync_ascents(round, round_result, ascent_data)
      return unless ascent_data

      ascent_data.each do |data|
        route = round.routes.find_by(external_route_id: data["route_id"])
        next unless route

        ascent = Ascent.find_or_initialize_by(round_result:, route:)
        update_ascent(ascent, data, round.category.discipline)
        ascent.save!
      end
    end

    def update_ascent(ascent, data, discipline)
      ascent.assign_attributes(
        ascent_status: data["status"],
        modified_at: data["modified"] ? Time.zone.parse(data["modified"]) : nil,
      )

      case discipline
      when "speed"
        ascent.assign_attributes(
          time_ms: data["time_ms"],
          dnf: data["dnf"] || false,
          dns: data["dns"] || false,
        )
      when "lead"
        ascent.assign_attributes(
          top: data["top"] || false,
          height: data["score"]&.to_d,
          plus: data["plus"] || false,
          rank: data["rank"],
          score_raw: data["score"],
        )
      else
        ascent.assign_attributes(
          top: data["top"] || false,
          top_tries: data["top_tries"],
          zone: data["zone"] || false,
          zone_tries: data["zone_tries"],
          low_zone: data["low_zone"] || false,
          low_zone_tries: data["low_zone_tries"],
          points: data["points"],
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
      athlete = Athlete.find_or_initialize_by(source: :ifsc, external_athlete_id: entry["athlete_id"])
      if athlete.new_record?
        athlete.update!(
          first_name: entry["firstname"],
          last_name: entry["lastname"],
          country_code: entry["country"],
          flag_url: entry["flag_url"],
        )
      elsif entry["flag_url"].present? && athlete.flag_url.blank?
        athlete.update!(flag_url: entry["flag_url"])
      end
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
