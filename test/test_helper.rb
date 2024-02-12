# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/test'
require 'capybara/minitest'
require_relative '../app'

ENV['APP_ENV'] = 'test'

Capybara.app = Sinatra::Application
Capybara.server = :puma, { Silent: true }

class TestCase < Minitest::Test
  private

  attr_reader :fixtures

  def setup
    super
    @fixtures = { notes: {} }
  end

  def clean_up_db
    pg_connection.exec('TRUNCATE notes RESTART IDENTITY CASCADE')
  end

  def pg_connection
    @pg_connection ||= PG::Connection.new(host: ENV['PG_HOST'],
                                          user: ENV['PG_USER'],
                                          password: ENV['PG_PASSWORD'])
    @pg_connection.type_map_for_results = PG::BasicTypeMapForResults.new(@pg_connection)
    @pg_connection.type_map_for_queries = PG::BasicTypeMapForQueries.new(@pg_connection)

    @pg_connection
  end

  def create_fixtures
    create_note_fixture(:first, 'note1 text', 1)
    create_note_fixture(:second, 'note2 text', 2)
  end

  def create_note_fixture(tag, text = 'whatever', position, updated_at: Time.now)
    inserted_id = pg_connection.exec_params('INSERT INTO notes (text, position, updated_at) VALUES ($1, $2, $3) RETURNING id',
                                            [text, position, updated_at]).getvalue(0, 0)
    row = pg_connection.exec_params('SELECT * FROM notes WHERE id = $1', [inserted_id])
    fixture = OpenStruct.new(id: row[0]['id'], text: row[0]['text'], position: row[0]['position'],
                             updated_at: row[0]['updated_at'])
    @fixtures[:notes][tag] = fixture
    fixture
  end
end

class SystemTestCase < TestCase
  include Rack::Test::Methods
  include Capybara::DSL
  include Capybara::Minitest::Assertions

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
    clean_up_db
  end

  def app
    Sinatra::Application
  end
end

class IntegrationTestCase < TestCase
  include Rack::Test::Methods

  private

  def teardown
    super
    clean_up_db
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
