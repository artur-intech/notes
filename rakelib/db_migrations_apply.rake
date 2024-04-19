# frozen_string_literal: true

desc 'Apply pending migrations'
namespace :db do
  namespace :migrations do
    task :apply do
      pg_host = ENV.fetch('PG_HOST', nil)
      pg_user = ENV.fetch('PG_USER', nil)
      pg_password = ENV.fetch('PG_PASSWORD', nil)
      pg_connection = PG::Connection.new(host: pg_host,
                                         user: pg_user,
                                         password: pg_password)

      migrations = PendingMigrations.new(Migrations.new(pg_connection:))

      if migrations.none?
        puts 'There are no pending migrations.'
        next
      end

      begin
        migrations.apply do |migration|
          puts "Migration #{migration} has been applied"
        end
      rescue Migration::InvalidMigrationError => e
        puts e.message
        next
      end

      PgSchema.new(pg_connection:).regenerate
    end
  end
end
