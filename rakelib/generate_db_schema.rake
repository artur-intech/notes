# frozen_string_literal: true

import 'app.rb'

# :nocov:
task :generate_db_schema do
  pg_host = ENV.fetch('PG_HOST', nil)
  pg_user = ENV.fetch('PG_USER', nil)
  pg_password = ENV.fetch('PG_PASSWORD', nil)
  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)

  PgSchema.new(pg_connection:).generate
end
# :nocov:
