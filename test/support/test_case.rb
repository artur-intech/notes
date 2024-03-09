# frozen_string_literal: true

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

  def plain_password
    'test'
  end
  alias right_password plain_password
end
