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

  def assert_json_response
    assert_equal Rack::Mime.mime_type('.json'), last_response['content-type']
  end

  def user
    PgUser.new(super.id, pg_connection)
  end
end
