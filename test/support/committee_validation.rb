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
