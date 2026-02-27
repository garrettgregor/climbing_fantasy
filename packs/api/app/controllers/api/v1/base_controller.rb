module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend

      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      private

      def not_found
        render(json: { error: "Not found" }, status: :not_found)
      end

      def pagination_meta(pagy)
        {
          page: pagy.page,
          per_page: pagy.limit,
          total: pagy.count,
        }
      end
    end
  end
end
