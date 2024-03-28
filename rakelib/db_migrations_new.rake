# frozen_string_literal: true

desc 'Generate new migration'
namespace :db do
  namespace :migrations do
    task :new, [:name] do |_t, args|
      name = args.name
      id = TimestampedId.new(name:)
      migration = Migrations.new(path: 'db/migrations', pg_connection:).generate(id:)

      puts "Migration #{migration.path} has been created."
    end
  end
end
