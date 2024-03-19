# frozen_string_literal: true

class PgUsers
  class UserNotFoundError < StandardError; end

  class ExistingUserError < StandardError
    def initialize
      super('Email is already taken.')
    end
  end

  def initialize(pg_connection, user_by_id = proc { |id| PgUser.new(id, pg_connection) })
    @pg_connection = pg_connection
    @user_by_id = user_by_id
  end

  def by_email(email)
    result = pg_connection.exec_params('SELECT id FROM users WHERE email = $1', [email])
    raise UserNotFoundError if result.num_tuples.zero?

    id = result.getvalue(0, 0)
    user_by_id.call(id)
  end

  def add(email:, plain_password:)
    raise ArgumentError, 'Email cannot be nil' if email.nil?
    raise ArgumentError, 'Email cannot be empty' if email.empty?
    raise ArgumentError, "Invalid email (#{email})" if email_invalid?(email)
    raise ArgumentError, 'Password cannot be nil' if plain_password.nil?
    raise ArgumentError, 'Password cannot be empty' if plain_password.empty?
    raise ExistingUserError if existing_user?(email)

    encrypted_password = BCrypt::Password.create(plain_password)

    sql = 'INSERT INTO users (email, encrypted_password) VALUES ($1, $2) RETURNING id'
    result = pg_connection.exec_params(sql, [email, encrypted_password])
    result.getvalue(0, 0)
  end

  private

  attr_reader :pg_connection, :user_by_id

  def existing_user?(email)
    pg_connection.exec_params('SELECT id FROM users WHERE email = $1', [email]).ntuples.nonzero?
  end

  def email_invalid?(email)
    pattern = URI::MailTo::EMAIL_REGEXP
    email !~ pattern
  end
end
