# frozen_string_literal: true

import 'app.rb'

# :nocov:
task :load_db_schema do
  pg_host = ENV.fetch('PG_HOST', nil)
  pg_user = ENV.fetch('PG_USER', nil)
  pg_password = ENV.fetch('PG_PASSWORD', nil)
  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)

  schema_file_path = PgSchema.new(pg_connection:).path
  `PGPASSWORD=#{pg_password} psql --host #{pg_host} --username #{pg_user} --file #{schema_file_path}`
end
# :nocov:
