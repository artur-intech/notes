# frozen_string_literal: true

import 'app.rb'

# :nocov:
task :create_db do
  pg_host = ENV.fetch('PG_HOST', nil)
  pg_user = ENV.fetch('PG_USER', nil)
  pg_password = ENV.fetch('PG_PASSWORD', nil)
  pg_database = pg_user

  `PGPASSWORD=#{pg_password} createdb -h #{pg_host} -U #{pg_user} #{pg_database}`

  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)
  pg_connection.exec("GRANT ALL PRIVILEGES ON DATABASE #{pg_database} to #{pg_user};")
end
# :nocov:
