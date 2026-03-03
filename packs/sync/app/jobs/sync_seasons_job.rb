class SyncSeasonsJob < ApplicationJob
  queue_as :sync

  def perform
    client = Ifsc::ApiClient.new
    Ifsc::SeasonSyncer.call(client:)

    Event.pending_sync.find_each do |event|
      Ifsc::EventSyncer.call(event:, client:)
    rescue Ifsc::ApiClient::ApiError => e
      Rails.logger.error("SyncSeasonsJob: Failed to sync event #{event.external_id}: #{e.message}")
    end
  end
end
