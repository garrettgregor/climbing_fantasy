ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into(:webmock)
  config.allow_http_connections_when_no_cassette = true
  config.default_cassette_options = { re_record_interval: 7.days }
  config.filter_sensitive_data("<IFSC_SESSION_COOKIE>") do |interaction|
    cookie = interaction.request.headers["Cookie"]&.first
    if cookie
      match = cookie.match(/_verticallife_resultservice_session=([^;]+)/)
      match[1] if match
    end
  end
  config.filter_sensitive_data("<IFSC_SESSION_COOKIE>") do |interaction|
    set_cookie = interaction.response.headers["Set-Cookie"]&.first
    if set_cookie
      match = set_cookie.match(/_verticallife_resultservice_session=([^;]+)/)
      match[1] if match
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

# Committee schema validation for API tests
module CommitteeValidation
  SCHEMA_PATH = Rails.root.join("swagger/v1/swagger.yaml").to_s

  def assert_schema_conform
    assert_schema_conform!
  end

  def assert_schema_conform!
    schema = Committee::Drivers.load_from_file(SCHEMA_PATH)
    validator = Committee::SchemaValidator::OpenAPI3::ResponseValidator.new(
      schema.open_api,
      validator_option: Committee::SchemaValidator::Option.new({}, schema, :open_api_3),
    )
    status = response.status
    headers = response.headers
    body = response.body
    validator.call(request, status, headers, [body], strict: false)
  rescue Committee::InvalidResponse => e
    flunk("Response does not conform to OpenAPI schema: #{e.message}")
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework(:minitest)
    with.library(:rails)
  end
end
