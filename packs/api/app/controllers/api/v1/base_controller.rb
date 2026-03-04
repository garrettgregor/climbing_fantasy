module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Method

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

      # Pagy 43 no longer has the overflow extra; clamp overflowing requests to last page.
      def paginate_with_last_page(collection)
        limit = params.fetch(:per_page, 25).to_i
        limit = 25 if limit <= 0

        requested_page = params.fetch(:page, 1).to_i
        requested_page = 1 if requested_page <= 0

        count = collection.count(:all)
        last_page = [(count.to_f / limit).ceil, 1].max

        pagy(:offset, collection, limit:, page: [requested_page, last_page].min, count:)
      end
    end
  end
end
