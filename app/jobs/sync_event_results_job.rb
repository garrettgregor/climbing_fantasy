class SyncEventResultsJob < ApplicationJob
  queue_as :scraping

  def perform(adapter: :net_http, stubs: nil)
    client = Ifsc::Client.new(adapter: adapter, stubs: stubs)

    Competition.where(status: [ :in_progress, :completed ]).find_each do |competition|
      next unless competition.external_event_id

      event_data = client.fetch_event_results(competition.external_event_id)
      Ifsc::ResultSyncer.sync_categories(competition, event_data)

      competition.categories.find_each do |category|
        next unless category.external_category_id

        result_data = client.fetch_category_results(
          competition.external_event_id,
          category.external_category_id
        )
        Ifsc::ResultSyncer.sync_results(category, result_data)
      end
    rescue Ifsc::Client::ApiError => e
      Rails.logger.error "Failed to sync event #{competition.id}: #{e.message}"
    end
  end
end
