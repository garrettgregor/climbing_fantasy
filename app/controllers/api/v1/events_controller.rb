module Api
  module V1
    class EventsController < BaseController
      def index
        scope = Event.all
        scope = scope.where(season_id: params[:season_id]) if params[:season_id].present?
        scope = scope.where(discipline: params[:discipline]) if params[:discipline].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.joins(:season).where(seasons: { year: params[:year] }) if params[:year].present?

        pagy, events = pagy(scope.order(starts_on: :desc), limit: params.fetch(:per_page, 25).to_i)
        render json: {
          data: EventBlueprint.render_as_hash(events),
          meta: pagination_meta(pagy)
        }
      end

      def show
        event = Event.find(params[:id])
        render json: {
          data: EventBlueprint.render_as_hash(event, view: :extended)
        }
      end
    end
  end
end
