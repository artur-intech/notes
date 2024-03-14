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
    fixtures[:notes].select { |_k, note| note.user_id == user.id }.values.reverse
  end

  def db_user_note_count
    pg_connection.exec_params('SELECT COUNT(*) FROM notes WHERE user_id = $1', [user.id]).getvalue(0, 0)
  end

  def assert_difference(expression, expected = 1, &block)
    original_value = expression.call
    block.call
    new_value = expression.call

    actual = new_value - original_value

    message = %(The expression wasn't changed by #{expected}, but by #{actual})
    assert expected == actual, message
  end

  def assert_no_difference(expression, message = nil, &block)
    original_value = expression.call
    block.call
    new_value = expression.call

    message ||= %(The expression must not be changed, but it changed from "#{original_value}" to "#{new_value}")
    assert original_value == new_value, message
  end

  # Minitest already has `assert_same`
  def assert_no_change(expression, message = nil, &block)
    assert_no_difference(expression, message, &block)
  end

  def assert_change_to(expression, expected, &block)
    before = expression.call
    refute_equal before, expected

    block.call
    after = expression.call

    message = %(Must have been changed to "#{expected}", but it remained "#{after}")
    assert expected == after, message
  end

  def assert_change(expression, &block)
    before = expression.call
    block.call
    after = expression.call

    message = %(Must have been changed, but it remained the same)
    assert before != after, message
  end

  def db_note_count
    pg_connection.exec('SELECT COUNT(*) FROM notes').getvalue(0, 0)
  end
end
