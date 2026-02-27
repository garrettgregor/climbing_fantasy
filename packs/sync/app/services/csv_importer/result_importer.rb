require "csv"

module CsvImporter
  class ResultImporter
    DISCIPLINE_MAP = {
      "boulder" => :boulder,
      "lead" => :lead,
      "speed" => :speed,
      "combined" => :combined,
      "boulder&lead" => :boulder_and_lead,
    }.freeze

    class << self
      # rubocop:disable Rails/Delegate -- `delegate :import, to: :new` doesn't convey intent here
      def import(file_path)
        new.import(file_path)
      end
      # rubocop:enable Rails/Delegate
    end

    def import(file_path)
      @seasons = {}
      @events = {}
      @categories = {}
      @rounds = {}
      @athletes = Athlete.where.not(external_athlete_id: nil).index_by(&:external_athlete_id)
      @row_count = 0
      @skipped = 0

      ActiveRecord::Base.transaction do
        CSV.foreach(file_path, headers: true) do |row|
          @row_count += 1
          import_row(row)
          log_progress if (@row_count % 10_000).zero?
        end
      end

      Rails.logger.info("ResultImporter complete: #{@row_count} rows processed, #{@skipped} skipped")
    end

    private

    def import_row(row)
      athlete = @athletes[row["athlete_id"].to_i]
      unless athlete
        @skipped += 1
        return
      end

      discipline = DISCIPLINE_MAP[row["discipline"]]
      return unless discipline

      season = find_or_create_season(row["season"].to_i)
      event = find_or_create_event(season, row, discipline)
      category = find_or_create_category(event, row, discipline, athlete)
      round = find_or_create_round(category)

      find_or_create_result(round, athlete, row["rank"].to_i)
    end

    def find_or_create_season(year)
      @seasons[year] ||= Season.find_or_create_by!(year: year) do |s|
        s.name = "IFSC World Cup #{year}"
      end
    end

    def find_or_create_event(season, row, discipline)
      event_id = row["event_id"].to_i
      cache_key = "#{season.id}-#{event_id}"

      @events[cache_key] ||= Event.find_or_create_by!(
        season: season,
        external_id: event_id,
      ) do |e|
        date = begin
          Date.parse(row["date"])
        rescue
          Date.new(season.year, 1, 1)
        end
        location = row["event_location"].presence || "Unknown"
        e.name = "IFSC World Cup #{location} #{season.year}"
        e.location = location
        e.discipline = discipline
        e.starts_on = date
        e.ends_on = date
        e.status = :completed
      end
    end

    def find_or_create_category(event, row, discipline, athlete)
      d_cat = row["d_cat"].to_i
      cache_key = "#{event.id}-#{d_cat}"

      @categories[cache_key] ||= Category.find_or_create_by!(
        event: event,
        external_id: d_cat,
      ) do |c|
        c.name = "#{discipline.to_s.titleize} - #{athlete.gender.titleize}"
        c.discipline = discipline
        c.gender = athlete.gender
        c.age_category = :open
      end
    end

    def find_or_create_round(category)
      @rounds[category.id] ||= Round.find_or_create_by!(category: category, name: "Overall") do |r|
        r.round_type = :final
        r.status = :completed
      end
    end

    def find_or_create_result(round, athlete, rank)
      RoundResult.find_or_create_by!(round: round, athlete: athlete) do |rr|
        rr.rank = rank
      end
    end

    def log_progress
      Rails.logger.info("ResultImporter: processed #{@row_count} rows (#{@skipped} skipped)...")
    end
  end
end
