class SyncUpcomingEventsJob < ApplicationJob
  queue_as :scraping

  def perform(adapter: :net_http, stubs: nil)
    client = Ifsc::Client.new(adapter: adapter, stubs: stubs)

    Event.upcoming.find_each do |event|
      next unless event.external_id

      event_data = client.fetch_event_results(event.external_id)
      Ifsc::ResultSyncer.sync_categories(event, event_data)
    rescue Ifsc::Client::ApiError => e
      Rails.logger.error "Failed to sync upcoming event #{event.id}: #{e.message}"
    end
  end
end
