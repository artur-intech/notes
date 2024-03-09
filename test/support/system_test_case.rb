# frozen_string_literal: true

class SystemTestCase < TestCase
  include Rack::Test::Methods
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include Warden::Test::Helpers

  private

  def setup
    super
    Capybara.current_driver = :selenium_chrome_headless
  end

  def teardown
    super
    Capybara.reset_sessions!
    Capybara.use_default_driver
    Warden.test_reset!
  end

  def app
    Sinatra::Application
  end
end
