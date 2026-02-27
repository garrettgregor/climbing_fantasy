module Api
  module V1
    class SeasonsController < BaseController
      def index
        pagy, seasons = pagy(Season.order(year: :desc), limit: params.fetch(:per_page, 25).to_i)
        render(json: {
          data: SeasonBlueprint.render_as_hash(seasons),
          meta: pagination_meta(pagy),
        })
      end

      def show
        season = Season.find(params[:id])
        render(json: {
          data: SeasonBlueprint.render_as_hash(season, view: :extended),
        })
      end
    end
  end
end
