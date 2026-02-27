module Api
  module V1
    class CategoriesController < BaseController
      def show
        category = Category.find(params[:id])
        render(json: {
          data: CategoryBlueprint.render_as_hash(category, view: :extended),
        })
      end
    end
  end
end
