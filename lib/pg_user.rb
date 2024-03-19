# frozen_string_literal: true

class PgUser
  attr_reader :id

  def initialize(id, pg_connection)
    @id = id
    @pg_connection = pg_connection
  end

  def can_be_authenticated?(plain_password)
    raise ArgumentError if plain_password.nil?
    raise ArgumentError if plain_password.empty?

    BCrypt::Password.new(encrypted_password) == plain_password
  end

  def email
    pg_connection.exec_params('SELECT email FROM users WHERE id = $1', [id]).getvalue(0, 0)
  end

  def ==(other)
    self.class == other.class && id == other.id
  end

  def inspect
    "#{id}, #{email}"
  end

  private

  attr_reader :pg_connection

  def encrypted_password
    pg_connection.exec_params('SELECT encrypted_password FROM users WHERE id = $1', [id]).getvalue(0, 0)
  end
end
