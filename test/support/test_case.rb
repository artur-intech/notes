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

  def user
    fixtures[:users][:first]
  end

  def user_notes
    fixtures[:notes].select { |_k, note| note.user_id == user.id }.values
  end

  def db_user_note_count
    pg_connection.exec_params('SELECT COUNT(*) FROM notes WHERE user_id = $1', [user.id]).getvalue(0, 0)
  end
end
