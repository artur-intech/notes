# frozen_string_literal: true

require 'test_helper'

class FakePgConnection
  class FakeResult
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def getvalue(_tup_num, _field_num)
      value
    end
  end

  attr_reader :value

  def initialize(value)
    @value = value
  end

  def exec_params(_sql, _params)
    FakeResult.new(value)
  end
end

class PgUserTest < TestCase
  def test_reports_email
    pg_user = PgUser.new(user.id, pg_connection)

    assert_equal user.email, pg_user.email
  end

  def test_reports_whether_it_can_be_authenticated
    pg_user = PgUser.new(user.id, pg_connection)

    assert pg_user.can_be_authenticated?(right_password)
    refute pg_user.can_be_authenticated?('wrong password')

    assert_raises ArgumentError, 'Password cannot be nil' do
      pg_user.can_be_authenticated?(nil)
    end

    assert_raises ArgumentError, 'Password cannot be empty' do
      pg_user.can_be_authenticated?('')
    end
  end

  def test_equality
    one = PgUser.new(1, pg_connection)
    two = PgUser.new(2, pg_connection)

    assert_equal one, one
    refute_equal one, two
    refute_equal one, {}
  end

  def test_inspect
    id = 1
    email = 'email'
    user = PgUser.new(id, FakePgConnection.new(email))

    assert_equal "#{id}, #{email}", user.inspect
  end
end
