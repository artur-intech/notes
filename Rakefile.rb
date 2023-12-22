require 'minitest/test_task'
require 'pg'

Minitest::TestTask.create

pg_host = 'localhost'

task :create_db, [:environment] do |_t, args|
  pg_user = "notes_#{args.environment}"
  pg_password = pg_user
  pg_database = "notes_#{args.environment}"

  `PGPASSWORD=#{pg_password} createdb -h #{pg_host} -U #{pg_user} #{pg_database}`

  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)
  pg_connection.exec("GRANT ALL PRIVILEGES ON DATABASE #{pg_database} to #{pg_user};")
end

task :drop_db, [:environment] do |_t, args|
  pg_user = "notes_#{args.environment}"
  pg_password = pg_user
  pg_database = "notes_#{args.environment}"

  `PGPASSWORD=#{pg_password} dropdb -h #{pg_host} -U #{pg_user} -f #{pg_database}`
end

task :load_db_schema, [:environment] do |_t, args|
  pg_user = "notes_#{args.environment}"
  pg_password = pg_user

  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)
  pg_connection.exec(File.read('db/schema.pgsql'))
end

task :load_db_dummy_data do
  environment = 'development'
  pg_user = "notes_#{environment}"
  pg_password = pg_user

  pg_connection = PG::Connection.new(host: pg_host,
                                     user: pg_user,
                                     password: pg_password)
  pg_connection.exec("INSERT INTO notes (text) VALUES ('Deutsch'), ('English'), ('TODO');")
end
