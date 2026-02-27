module Api
  module V1
    class RoundsController < BaseController
      def show
        round = Round.includes(round_results: :athlete).find(params[:id])
        render(json: {
          data: RoundBlueprint.render_as_hash(round, view: :extended),
        })
      end
    end
  end
end
