module Api
  module V1
    class AthletesController < BaseController
      def index
        pagy, athletes = paginate_with_last_page(AthleteQuery.call(params).order(:last_name, :first_name))
        render(json: {
          data: AthleteBlueprint.render_as_hash(athletes),
          meta: pagination_meta(pagy),
        })
      end

      def show
        athlete = Athlete.find(params[:id])
        render(json: {
          data: AthleteBlueprint.render_as_hash(athlete, view: :extended),
        })
      end
    end
  end
end
