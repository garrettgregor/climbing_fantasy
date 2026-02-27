class SyncSeasonsJob < ApplicationJob
  queue_as :scraping

  def perform(adapter: :net_http, stubs: nil)
    client = Ifsc::Client.new(adapter: adapter, stubs: stubs)
    data = client.fetch_seasons
    Ifsc::ResultSyncer.sync_seasons(data)
  end
end
