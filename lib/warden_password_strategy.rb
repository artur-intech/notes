# frozen_string_literal: true

class WardenPasswordStrategy < Warden::Strategies::Base
  def valid?
    params['email'] && params['password']
  end

  def authenticate!
    pg_users = PgUsers.new(pg_connection)
    pg_user = pg_users.by_email(params['email'])

    success!(pg_user) if pg_user.can_be_authenticated?(params['password'])
  rescue PgUsers::UserNotFoundError
    fail!('User with the provided email does not exist.')
  end
end
