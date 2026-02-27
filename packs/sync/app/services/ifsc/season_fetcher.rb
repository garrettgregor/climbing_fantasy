module Ifsc
  class SeasonFetcher
    def initialize(client:)
      @client = client
    end

    def call
      data = @client.fetch_seasons
      ResultSyncer.sync_seasons(data)
    end
  end
end
