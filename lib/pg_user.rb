# frozen_string_literal: true

class PgUser
  attr_reader :id

  def initialize(id, pg_connection)
    @id = id
    @pg_connection = pg_connection
  end

  def can_be_authenticated?(plain_password)
    encrypted_password = pg_connection.exec_params('SELECT encrypted_password FROM users WHERE id = $1', [id])
                                      .getvalue(0, 0)
    BCrypt::Password.new(encrypted_password) == plain_password
  end

  def email
    pg_connection.exec_params('SELECT email FROM users WHERE id = $1', [id]).getvalue(0, 0)
  end

  private

  attr_reader :pg_connection
end