module Ifsc
  class ResultSyncer
    class << self
      def sync_seasons(data)
        data["seasons"]&.each do |season_data|
          season = Season.find_or_initialize_by(external_id: season_data["id"])
          season.name = season_data["name"]
          season.year = extract_year(season_data["name"])
          season.save!

          season_data["leagues"]&.each do |league|
            league["events"]&.each do |event_data|
              sync_event(season, event_data)
            end
          end
        end
      end

      def sync_categories(event, data)
        data["d_cats"]&.each do |dcat|
          category = event.categories.find_or_initialize_by(
            external_id: dcat["dcat_id"],
          )
          category.name = dcat["dcat_name"]
          category.discipline = map_discipline(dcat["discipline"])
          category.gender = map_gender(dcat["category"])
          category.age_category = category.canonical_age_category
          category.save!
        end
      end

      def sync_results(category, data)
        data["ranking"]&.each do |ranking|
          athlete = find_or_create_athlete(ranking)

          ranking["rounds"]&.each do |round_data|
            round = category.rounds.find_or_initialize_by(
              external_round_id: round_data["round_id"],
            )
            round.name = round_data["round_name"]
            round.round_type = map_round_type(round_data["round_name"])
            round.status = :completed
            round.save!

            result = round.round_results.find_or_initialize_by(athlete: athlete)
            result.rank = round_data["rank"]
            result.score_raw = round_data["score"]
            result.tops = round_data["tops"]
            result.zones = round_data["zones"]
            result.top_attempts = round_data["top_attempts"]
            result.zone_attempts = round_data["zone_attempts"]
            result.lead_height = round_data["lead_height"]
            result.lead_plus = round_data["lead_plus"] || false
            result.speed_time = round_data["speed_time"]
            result.speed_eliminated_stage = round_data["speed_eliminated_stage"]
            result.save!
          end
        end
      end

      private

      def sync_event(season, event_data)
        event = season.events.find_or_initialize_by(
          external_id: event_data["event_id"],
        )
        event.name = event_data["event"]
        event.location = event_data["location"] || "TBD"
        event.starts_on = Date.parse(event_data["starts_at"])
        event.ends_on = Date.parse(event_data["ends_at"])
        event.discipline = infer_discipline(event_data["event"])
        event.status = infer_status(event.starts_on, event.ends_on)
        event.save!
      end

      def find_or_create_athlete(ranking)
        Athlete.find_or_create_by!(external_athlete_id: ranking["athlete_id"]) do |a|
          a.first_name = ranking["firstname"]
          a.last_name = ranking["lastname"]
          a.country_code = ranking["country"] || "UNK"
          a.gender = :male # Default; updated when category gender is known
        end
      end

      def extract_year(name)
        match = name.match(/(\d{4})/)
        match ? match[1].to_i : Date.current.year
      end

      def infer_discipline(event_name)
        name = event_name.downcase
        return :boulder_and_lead if name.include?("boulder") && name.include?("lead")
        return :combined if name.include?("combined")
        return :boulder if name.include?("boulder")
        return :lead if name.include?("lead")
        return :speed if name.include?("speed")

        :boulder # default
      end

      def infer_status(starts_on, ends_on)
        today = Date.current
        if today < starts_on
          :upcoming
        elsif today > ends_on
          :completed
        else
          :in_progress
        end
      end

      def map_discipline(discipline_str)
        case discipline_str&.downcase
        when "boulder" then :boulder
        when "lead" then :lead
        when "speed" then :speed
        when "combined" then :combined
        when "boulder&lead", "boulder_and_lead" then :boulder_and_lead
        else :boulder
        end
      end

      def map_gender(category_str)
        case category_str&.downcase
        when "men", "male" then :male
        when "women", "female" then :female
        else :male
        end
      end

      def map_round_type(round_name)
        name = round_name&.downcase
        return :final        if name&.match?(/final/) && !name&.match?(/semi|small|quarter/)
        return :small_final  if name&.match?(/small.final|3rd/)
        return :semi_final   if name&.match?(/semi/)
        return :quarter_final if name&.match?(/quarter/)
        return :round_of_16 if name&.match?(%r{round.of.16|1/8})

        :qualification
      end
    end
  end
end
