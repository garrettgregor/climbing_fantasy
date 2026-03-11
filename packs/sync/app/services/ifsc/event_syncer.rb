module Ifsc
  class EventSyncer
    SYNCABLE_DISCIPLINES = ["speed", "boulder", "lead"].freeze

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
      data = @client.get_event(@event.external_id)
      location = data["location"]

      if location.blank?
        raise ApiClient::ApiError, "Event #{@event.external_id} missing location in event payload"
      end

      data["d_cats"].each do |d_cat|
        next if SYNCABLE_DISCIPLINES.exclude?(d_cat["discipline_kind"].to_s.downcase)

        sync_category(d_cat)
      end

      @event.update!(
        sync_state: :needs_results,
        location:,
      )
    end

    private

    def sync_category(d_cat)
      gender = parse_gender(d_cat["category_name"])
      return unless gender

      category = Category.find_or_create_by!(event: @event, external_dcat_id: d_cat["dcat_id"]) do |c|
        c.name = d_cat["dcat_name"]
        c.discipline = map_discipline(d_cat["discipline_kind"])
        c.gender = gender
      end
      category.update!(category_status: map_category_status(d_cat["status"]))

      d_cat["category_rounds"].each { |round_data| sync_round(category, round_data) }
    end

    def sync_round(category, round_data)
      round = Round.find_or_initialize_by(category:, external_round_id: round_data["category_round_id"])
      round.update!(
        name: round_data["name"],
        round_type: map_round_type(round_data["name"]),
        status: map_round_status(round_data["status"]),
      )

      round_data["routes"]&.each_with_index { |route, index| sync_route(round, route, index) }
    end

    def sync_route(round, route_data, index)
      group_label = route_data["name"]&.downcase
      group_label = nil if ["a", "b"].exclude?(group_label)

      Route.find_or_create_by!(
        round:,
        external_route_id: route_data["id"],
      ) do |r|
        r.route_name = route_data["name"]
        r.route_order = index
        r.group_label = group_label
      end
    end

    def map_discipline(kind)
      {
        "speed" => :speed,
        "boulder" => :boulder,
        "lead" => :lead,
      }.fetch(kind.to_s.downcase)
    end

    def parse_gender(category_name)
      case category_name.to_s
      when /\bMen\b/ then :male
      when /\bWomen\b/ then :female
      end
    end

    def map_round_type(name)
      case name.to_s
      when /qualification/i then :qualification
      when /round of 16/i then :round_of_16
      when /quarter.?final/i then :quarter_final
      when /semi.?final/i then :semi_final
      when /small.?final/i then :small_final
      when /final/i then :final
      else :qualification
      end
    end

    def map_round_status(status)
      case status.to_s
      when "finished" then :completed
      when "active" then :in_progress
      else :pending
      end
    end

    def map_category_status(status)
      case status.to_s
      when "finished" then :finished
      when "active" then :active
      else :not_started
      end
    end
  end
end
