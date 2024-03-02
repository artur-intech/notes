require 'minitest/test_task'
require 'pg'

Minitest::TestTask.create do |t|
  t.framework = %(require "test/test_helper.rb")
  t.libs = %w[test .]
  t.test_globs = ['test/**/*_test.rb']
end

task :create_db do
  pg_host = ENV['PG_HOST']
  pg_user = ENV['PG_USER']
  pg_password = ENV['PG_PASSWORD']
  pg_database = pg_user

  `PGPASSWORD=#{pg_password} createdb -h #{pg_host} -U #{pg_user} #{pg_database}`

  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)
  pg_connection.exec("GRANT ALL PRIVILEGES ON DATABASE #{pg_database} to #{pg_user};")
end

task :drop_db do
  pg_host = ENV['PG_HOST']
  pg_user = ENV['PG_USER']
  pg_password = ENV['PG_PASSWORD']
  pg_database = pg_user

  `PGPASSWORD=#{pg_password} dropdb -h #{pg_host} -U #{pg_user} -f #{pg_database}`
end

task :load_db_schema do
  pg_host = ENV['PG_HOST']
  pg_user = ENV['PG_USER']
  pg_password = ENV['PG_PASSWORD']

  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)
  pg_connection.exec(File.read('db/schema.pgsql'))
end

task :load_db_dummy_data do
  pg_host = ENV['PG_HOST']
  pg_user = ENV['PG_USER']
  pg_password = ENV['PG_PASSWORD']

  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)
  pg_connection.exec("INSERT INTO notes (text) VALUES ('Deutsch'), ('English'), ('TODO');")
end
