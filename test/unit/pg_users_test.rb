# frozen_string_literal: true

require 'test_helper'

class PgUserTest < TestCase
  def test_adds
    pwd = valid_password
    users = PgUsers.new(pg_connection)
    id = nil

    assert_difference proc { db_user_count } do
      id = users.add(email: valid_email, plain_password: pwd)
    end
    assert_equal fixtures[:users].size.next, id
    refute_equal pwd, db_password(id), 'Must not store plain password'

    error = assert_raises(ArgumentError) { users.add(email: nil, plain_password: valid_password) }
    assert_equal 'Email cannot be nil', error.message

    error = assert_raises(ArgumentError) { users.add(email: '', plain_password: valid_password) }
    assert_equal 'Email cannot be empty', error.message

    invalid_email = 'invalid'
    error = assert_raises(ArgumentError) { users.add(email: invalid_email, plain_password: valid_password) }
    assert_equal "Invalid email (#{invalid_email})", error.message

    error = assert_raises(ArgumentError) { users.add(email: valid_email, plain_password: nil) }
    assert_equal 'Password cannot be nil', error.message

    error = assert_raises(ArgumentError) { users.add(email: valid_email, plain_password: '') }
    assert_equal 'Password cannot be empty', error.message
  end

  def test_existing_user
    error = assert_raises PgUsers::ExistingUserError do
      PgUsers.new(pg_connection).add(email: user.email, plain_password: 'any')
    end
    assert_equal 'Email is already taken.', error.message
  end

  def test_fetches_user_by_email
    users = PgUsers.new(pg_connection)

    assert_equal PgUser.new(user.id, pg_connection), users.by_email(user.email)
    assert_raises(PgUsers::UserNotFoundError) { users.by_email('nonexistent') }
  end

  private

  def db_password(user_id)
    pg_connection.exec_params('SELECT encrypted_password FROM users WHERE id = $1', [user_id]).getvalue(0, 0)
  end
end
