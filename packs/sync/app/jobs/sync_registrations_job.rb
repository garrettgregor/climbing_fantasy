class SyncRegistrationsJob < ApplicationJob
  queue_as :sync

  def perform
    client = Ifsc::ApiClient.new

    Event.where(status: [:upcoming, :in_progress]).find_each do |event|
      Ifsc::RegistrationSyncer.call(event:, client:)
    rescue Ifsc::ApiClient::ApiError => e
      Rails.logger.error("SyncRegistrationsJob: Failed to sync registrations for event #{event.external_id}: #{e.message}")
    end
  end
end
