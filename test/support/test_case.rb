# frozen_string_literal: true

class TestCase < Minitest::Test
  include Assertions

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
  alias valid_password plain_password

  def user
    fixtures[:users][:first]
  end

  def user_notes
    fixtures[:notes].select { |_k, note| note.user_id == user.id }.values.reverse
  end

  def db_user_note_count
    pg_connection.exec_params('SELECT COUNT(*) FROM notes WHERE user_id = $1', [user.id]).getvalue(0, 0)
  end

  def db_note_count
    pg_connection.exec('SELECT COUNT(*) FROM notes').getvalue(0, 0)
  end

  def db_user_count
    pg_connection.exec('SELECT COUNT(*) FROM users').getvalue(0, 0)
  end

  def random_email
    local_part = SecureRandom.alphanumeric(5).downcase
    "#{local_part}@inbox.test"
  end
  alias valid_email random_email

  alias mute_io capture_io

  def create_tmp_dir
    Dir.mktmpdir do |path|
      Dir.chdir path do
        migrations_dir_path = File.join(path, 'db/migrations')
        FileUtils.mkdir_p migrations_dir_path
        yield migrations_dir_path
      end
    end
  end

  def create_tmp_file(name: '1234_test.sql', content: 'select 1', dir: Dir.tmpdir)
    path = File.join(dir, name)
    FileUtils.touch(path)
    File.write(path, content)
    yield path, name
  ensure
    File.delete path
  end
end
