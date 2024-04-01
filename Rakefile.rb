# frozen_string_literal: true

require 'minitest/test_task'

import 'app.rb'

Minitest::TestTask.create do |t|
  t.framework = %(require "test/test_helper.rb")
  t.libs = %w[test .]
  t.test_globs = ['test/**/*_test.rb']
end

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

task :drop_db do
  pg_host = ENV.fetch('PG_HOST', nil)
  pg_user = ENV.fetch('PG_USER', nil)
  pg_password = ENV.fetch('PG_PASSWORD', nil)
  pg_database = pg_user

  `PGPASSWORD=#{pg_password} dropdb -h #{pg_host} -U #{pg_user} -f #{pg_database}`
end

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

task :generate_db_schema do
  pg_host = ENV.fetch('PG_HOST', nil)
  pg_user = ENV.fetch('PG_USER', nil)
  pg_password = ENV.fetch('PG_PASSWORD', nil)
  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)

  PgSchema.new(pg_connection:).generate
end

task :load_db_dummy_data do
  pg_host = ENV.fetch('PG_HOST', nil)
  pg_user = ENV.fetch('PG_USER', nil)
  pg_password = ENV.fetch('PG_PASSWORD', nil)

  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)
  pg_connection.exec("INSERT INTO notes (text) VALUES ('Deutsch'), ('English'), ('TODO');")
end
