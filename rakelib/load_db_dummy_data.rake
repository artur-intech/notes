# frozen_string_literal: true

import 'app.rb'

# :nocov:
task :load_db_dummy_data do
  pg_host = ENV.fetch('PG_HOST', nil)
  pg_user = ENV.fetch('PG_USER', nil)
  pg_password = ENV.fetch('PG_PASSWORD', nil)

  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)
  pg_connection.exec("INSERT INTO notes (text) VALUES ('Deutsch'), ('English'), ('TODO');")
end
# :nocov:
