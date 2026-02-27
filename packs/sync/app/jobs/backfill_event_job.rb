class BackfillEventJob < ApplicationJob
  queue_as :scraping

  def perform(event_id)
    event = Event.find(event_id)
    return if event.results_synced_at.present?

    scraper = Ifsc::DomScraper.new

    event.categories.find_each do |category|
      next unless category.external_id && event.external_id

      data = scraper.fetch_category_results(event.external_id, category.external_id)
      Ifsc::ResultSyncer.sync_results(category, data)
    end

    event.update!(results_synced_at: Time.current)
  rescue Ferrum::Error => e
    Rails.logger.error("BackfillEventJob: Ferrum error for event #{event_id}: #{e.message}")
    raise
  rescue Ifsc::DomScraper::ScraperError => e
    Rails.logger.error("BackfillEventJob: ScraperError for event #{event_id}: #{e.message}")
    raise
  ensure
    scraper&.close
  end
end
