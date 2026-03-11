module Ifsc
  class RegistrationSyncer
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
      registrations = @client.get_event_registrations(@event.external_id)

      registrations.each { |reg| sync_registration(reg) }

      @event.update!(registrations_last_checked_at: Time.current)
    end

    private

    def sync_registration(reg)
      athlete = find_or_create_athlete(reg)

      reg["d_cats"].each do |d_cat|
        category = @event.categories.find_by(name: d_cat["name"])
        next unless category

        CategoryRegistration.find_or_create_by!(category:, athlete:)
      end
    end

    def find_or_create_athlete(reg)
      athlete = Athlete.find_or_initialize_by(source: :ifsc, external_athlete_id: reg["athlete_id"])
      was_new = athlete.new_record?
      athlete.update!(
        first_name: reg["firstname"],
        last_name: reg["lastname"],
        country_code: reg["country"],
        gender: map_gender(reg["gender"]),
        federation: reg["federation"],
        federation_id: reg["federation_id"],
      )
      enrich_athlete(athlete) if was_new || athlete.photo_url.blank?
      athlete
    end

    def enrich_athlete(athlete)
      data = @client.get_athlete(athlete.external_athlete_id)
      attrs = {}
      attrs[:photo_url] = data["photo_url"] if data["photo_url"].present? && athlete.photo_url.blank?
      attrs[:flag_url] = data["flag_url"] if data["flag_url"].present? && athlete.flag_url.blank?
      athlete.update!(attrs) if attrs.any?
    rescue StandardError => e
      Rails.logger.warn("Failed to enrich athlete #{athlete.external_athlete_id}: #{e.message}")
    end

    def map_gender(value)
      case value
      when 0 then :male
      when 1 then :female
      end
    end
  end
end
