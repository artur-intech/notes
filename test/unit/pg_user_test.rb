# frozen_string_literal: true

require 'test_helper'

class PgUserTest < TestCase
  def test_reports_email
    pg_user = PgUser.new(user.id, pg_connection)
    assert_equal user.email, pg_user.email
  end

  def test_reports_whether_it_can_be_authenticated
    pg_user = PgUser.new(user.id, pg_connection)

    assert pg_user.can_be_authenticated?(right_password)
    refute pg_user.can_be_authenticated?('wrong password')
  end

  def test_equality
    one = PgUser.new(1, pg_connection)
    two = PgUser.new(2, pg_connection)

    assert_equal one, one
    refute_equal one, two
    refute_equal one, {}
  end
end
