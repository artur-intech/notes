# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter '/test/'
  end
end

ENV['APP_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'capybara/minitest'
require 'support/fixtures'
require_relative '../app'

Capybara.app = Sinatra::Application
Capybara.server = :puma, { Silent: true }

class TestCase < Minitest::Test
  private

  attr_reader :fixtures

  def setup
    super
    @fixtures = Fixtures.new('test/fixtures.yml', pg_connection).to_hash
  end

  def teardown
    super
    clean_up_db
  end

  def clean_up_db
    pg_connection.exec('TRUNCATE users, notes RESTART IDENTITY CASCADE')
  end

  def random_email
    local_part = SecureRandom.alphanumeric(5).downcase
    "#{local_part}@inbox.test"
  end
  alias valid_email random_email

  # Encrypted version of the `#plain_password`
  def encrypted_password
    '$2a$12$3h3qyoaOag9y4HafevwnD.2bFz2lqjcWZFSu5UJU4V13xFYVhVNbO'
  end

  def plain_password
    'test'
  end
  alias right_password plain_password
end

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
end
