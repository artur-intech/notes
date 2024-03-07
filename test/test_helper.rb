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
require_relative '../app'

Capybara.app = Sinatra::Application
Capybara.server = :puma, { Silent: true }

class TestCase < Minitest::Test
  private

  attr_reader :fixtures

  def setup
    super
    @fixtures = { users: {}, notes: {} }
  end

  def teardown
    super
    clean_up_db
  end

  def clean_up_db
    pg_connection.exec('TRUNCATE notes RESTART IDENTITY CASCADE')
  end

  def create_fixtures
    user = create_user_fixture(tag: :first, email: random_email, encrypted_password:)
    create_note_fixture(:first, 'note1 text', 1, user_id: user.id)
    create_note_fixture(:second, 'note2 text', 2, user_id: user.id)
  end

  def create_note_fixture(tag, text = 'whatever', position, user_id:, updated_at: Time.now)
    inserted_id = pg_connection.exec_params('INSERT INTO notes (text, position, updated_at, user_id) VALUES ($1, $2, $3, $4) RETURNING id',
                                            [text, position, updated_at, user_id]).getvalue(0, 0)
    row = pg_connection.exec_params('SELECT * FROM notes WHERE id = $1', [inserted_id])
    fixture = OpenStruct.new(id: row[0]['id'], text: row[0]['text'], position: row[0]['position'],
                             updated_at: row[0]['updated_at'], user_id: row[0]['user_id'])
    @fixtures[:notes][tag] = fixture
    fixture
  end

  def create_user_fixture(tag:, email:, encrypted_password:)
    id = pg_connection.exec_params('INSERT INTO users (email, encrypted_password) VALUES ($1, $2) RETURNING id',
                                   [email, encrypted_password]).getvalue(0, 0)
    result = pg_connection.exec_params('SELECT * FROM users WHERE id = $1', [id])
    fixture = OpenStruct.new(id: result[0]['id'], email: result[0]['email'], position: result[0]['encrypted_password'])
    @fixtures[:users][tag] = fixture
    fixture
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
    create_fixtures
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
