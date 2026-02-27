module Ifsc
  class EventFetcher
    def initialize(client:)
      @client = client
    end

    def call(event)
      return unless event.external_id

      data = @client.fetch_event_results(event.external_id)
      ResultSyncer.sync_categories(event, data)
    end
  end
end
