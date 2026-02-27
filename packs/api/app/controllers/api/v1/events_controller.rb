module Api
  module V1
    class EventsController < BaseController
      def index
        pagy, events = pagy(EventQuery.call(params).order(starts_on: :desc), limit: params.fetch(:per_page, 25).to_i)
        render(json: {
          data: EventBlueprint.render_as_hash(events),
          meta: pagination_meta(pagy),
        })
      end

      def show
        event = Event.find(params[:id])
        render(json: {
          data: EventBlueprint.render_as_hash(event, view: :extended),
        })
      end
    end
  end
end
