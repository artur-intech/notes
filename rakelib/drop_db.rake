# frozen_string_literal: true

# :nocov:
task :drop_db do
  pg_host = ENV.fetch('PG_HOST', nil)
  pg_user = ENV.fetch('PG_USER', nil)
  pg_password = ENV.fetch('PG_PASSWORD', nil)
  pg_database = pg_user

  `PGPASSWORD=#{pg_password} dropdb -h #{pg_host} -U #{pg_user} -f #{pg_database}`
end
# :nocov:
