# frozen_string_literal: true

desc 'Initialize migrations'
namespace :db do
  namespace :migrations do
    task :init do
      pg_host = ENV.fetch('PG_HOST', nil)
      pg_user = ENV.fetch('PG_USER', nil)
      pg_password = ENV.fetch('PG_PASSWORD', nil)
      pg_connection = PG::Connection.new(host: pg_host,
                                         user: pg_user,
                                         password: pg_password)

      pg_connection.exec('CREATE TABLE applied_migrations(id character varying(255) NOT NULL UNIQUE)')
      Migrations.new(pg_connection:).create_path
      PgSchema.new(pg_connection:).generate

      puts 'Database migrations have been initialized. Generate one using `rake db:migrations:new[name]`.'
    end
  end
end
