require "test_helper"

class Ifsc::ClientTest < ActiveSupport::TestCase
  test "fetches seasons index" do
    stub_response = File.read(Rails.root.join("test/fixtures/files/ifsc_seasons_response.json"))
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/results-api.php?api=index") { [ 200, { "Content-Type" => "application/json" }, stub_response ] }
    end

    client = Ifsc::Client.new(adapter: :test, stubs: stubs)
    data = client.fetch_seasons

    assert data.key?("seasons")
    assert_equal 1, data["seasons"].length
    assert_equal 37, data["seasons"].first["id"]
  end

  test "fetches event results" do
    stub_response = File.read(Rails.root.join("test/fixtures/files/ifsc_event_results_response.json"))
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/results-api.php?api=event_results&event_id=1350") { [ 200, { "Content-Type" => "application/json" }, stub_response ] }
    end

    client = Ifsc::Client.new(adapter: :test, stubs: stubs)
    data = client.fetch_event_results(1350)

    assert data.key?("d_cats")
    assert_equal 2, data["d_cats"].length
  end

  test "fetches category results" do
    stub_response = File.read(Rails.root.join("test/fixtures/files/ifsc_category_results_response.json"))
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/api/v1/events/1350/result/5001") { [ 200, { "Content-Type" => "application/json" }, stub_response ] }
    end

    client = Ifsc::Client.new(adapter: :test, stubs: stubs)
    data = client.fetch_category_results(1350, 5001)

    assert data.key?("ranking")
    assert_equal 2, data["ranking"].length
  end

  test "raises on HTTP error" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/results-api.php?api=index") { [ 500, {}, "Internal Server Error" ] }
    end

    client = Ifsc::Client.new(adapter: :test, stubs: stubs)
    assert_raises(Ifsc::Client::ApiError) { client.fetch_seasons }
  end
end
