# frozen_string_literal: true

require 'test_helper'

class PgUserTest < TestCase
  def test_reports_email
    fixture = fixtures[:users][:first]
    pg_user = PgUser.new(fixture.id, pg_connection)
    assert_equal fixture.email, pg_user.email
  end

  def test_reports_whether_it_can_be_authenticated
    fixture = fixtures[:users][:first]

    pg_user = PgUser.new(fixture.id, pg_connection)

    assert pg_user.can_be_authenticated?(right_password)
    refute pg_user.can_be_authenticated?('wrong password')
  end
end
