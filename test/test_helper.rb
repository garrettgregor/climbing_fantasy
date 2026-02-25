ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

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
      validator_option: Committee::SchemaValidator::Option.new({}, schema, :open_api_3)
    )
    status, headers, body = response.status, response.headers, response.body
    validator.call(request, status, headers, [ body ], strict: false)
  rescue Committee::InvalidResponse => e
    flunk "Response does not conform to OpenAPI schema: #{e.message}"
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
