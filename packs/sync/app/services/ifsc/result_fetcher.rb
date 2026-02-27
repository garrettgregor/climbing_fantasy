module Ifsc
  class ResultFetcher
    def initialize(client:)
      @client = client
    end

    def call(category)
      event = category.event
      return unless event.external_id && category.external_id

      data = @client.fetch_category_results(event.external_id, category.external_id)
      ResultSyncer.sync_results(category, data)
    end
  end
end
