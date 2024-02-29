# frozen_string_literal: true

class PgUsers
  class UserNotFound < StandardError; end

  def initialize(pg_connection)
    @pg_connection = pg_connection
    @user_by_id = proc do |id|
      PgUser.new(id, pg_connection)
    end
  end

  def by_email(email)
    result = pg_connection.exec_params('SELECT id FROM users WHERE email = $1', [email])
    raise UserNotFound if result.num_tuples.zero?

    id = result.getvalue(0, 0)
    user_by_id.call(id)
  end

  private

  attr_reader :pg_connection, :user_by_id
end
