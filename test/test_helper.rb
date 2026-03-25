ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/action_dispatch_integration_test"
require_relative "support/committee_validation"
require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into(:webmock)
  config.allow_http_connections_when_no_cassette = true
  config.default_cassette_options = { record: :once }
  session_cookie_names = (
    Ifsc::ApiClient::SESSION_COOKIE_NAMES +
    ["_usac_resultservice_session"]
  ).uniq

  session_cookie_names.each do |cookie_name|
    config.filter_sensitive_data("<RESULTS_SESSION_COOKIE>") do |interaction|
      cookie = interaction.request.headers["Cookie"]&.first
      if cookie
        match = cookie.match(/#{cookie_name}=([^;]+)/)
        match[1] if match
      end
    end
    config.filter_sensitive_data("<RESULTS_SESSION_COOKIE>") do |interaction|
      set_cookie = interaction.response.headers["Set-Cookie"]&.first
      if set_cookie
        match = set_cookie.match(/#{cookie_name}=([^;]+)/)
        match[1] if match
      end
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework(:minitest)
    with.library(:rails)
  end
end
