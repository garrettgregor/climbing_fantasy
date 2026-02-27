class SyncEventResultsJob < ApplicationJob
  queue_as :scraping

  def perform(adapter: :net_http, stubs: nil)
    client = Ifsc::Client.new(adapter: adapter, stubs: stubs)

    Event.where(status: [:in_progress, :completed]).find_each do |event|
      next unless event.external_id
      next if event.results_synced_at.present?

      event_data = client.fetch_event_results(event.external_id)
      Ifsc::ResultSyncer.sync_categories(event, event_data)

      event.categories.find_each do |category|
        next unless category.external_id

        result_data = client.fetch_category_results(
          event.external_id,
          category.external_id,
        )
        Ifsc::ResultSyncer.sync_results(category, result_data)
      end

      event.update!(results_synced_at: Time.current) if event.completed?
    rescue Ifsc::Client::ApiError => e
      Rails.logger.error("Failed to sync event #{event.id}: #{e.message}")
    end
  end
end
