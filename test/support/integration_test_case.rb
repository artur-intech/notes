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

  def user
    PgUser.new(super.id, pg_connection)
  end
end
