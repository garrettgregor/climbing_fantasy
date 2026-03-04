module Api
  module V1
    class SeasonsController < BaseController
      def index
        pagy, seasons = paginate_with_last_page(Season.order(year: :desc))
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
