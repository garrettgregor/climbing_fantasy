module Api
  module V1
    class AthletesController < BaseController
      def index
        pagy, athletes = pagy(AthleteQuery.call(params).order(:last_name, :first_name), limit: params.fetch(:per_page, 25).to_i)
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
