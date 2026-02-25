require "test_helper"

class SyncSeasonsJobTest < ActiveJob::TestCase
  test "enqueues on scraping queue" do
    assert_enqueued_with(job: SyncSeasonsJob, queue: "scraping") do
      SyncSeasonsJob.perform_later
    end
  end

  test "calls client and syncer" do
    stub_data = {
      "seasons" => [
        {
          "id" => 99,
          "name" => "IFSC World Cup 2026",
          "leagues" => []
        }
      ]
    }
    stub_response = stub_data.to_json
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/results-api.php?api=index") { [ 200, { "Content-Type" => "application/json" }, stub_response ] }
    end

    assert_difference "Season.count", 1 do
      SyncSeasonsJob.perform_now(adapter: :test, stubs: stubs)
    end
  end
end
