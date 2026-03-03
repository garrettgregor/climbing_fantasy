class SyncResultsJob < ApplicationJob
  queue_as :sync

  def perform
    events = Event.where(status: :in_progress).or(Event.where(sync_state: :needs_results))
    return if events.none?

    client = Ifsc::ApiClient.new

    events.find_each do |event|
      Ifsc::ResultSyncer.call(event:, client:)
    rescue Ifsc::ApiClient::ApiError => e
      Rails.logger.error("SyncResultsJob: Failed to sync results for event #{event.external_id}: #{e.message}")
    end
  end
end
