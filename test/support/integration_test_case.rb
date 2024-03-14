# frozen_string_literal: true

class IntegrationTestCase < TestCase
  include Rack::Test::Methods
  include Warden::Test::Helpers

  private

  def teardown
    super
    Warden.test_reset!
  end

  def app
    Sinatra::Application
  end

  def json_response
    JSON.parse(last_response.body, symbolize_names: true)
  end

  def assert_json_response(expected_hash)
    assert_equal Rack::Mime.mime_type('.json'), last_response['content-type']
    assert_equal expected_hash, json_response
  end

  def user
    PgUser.new(super.id, pg_connection)
  end

  def assert_response(expected)
    actual = Rack::Utils::HTTP_STATUS_CODES[last_response.status].downcase
    assert last_response.public_send("#{expected}?"), "Response must be :#{expected}, but was :#{actual}"
  end
end
