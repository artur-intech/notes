# frozen_string_literal: true

desc 'Generate new migration'
namespace :db do
  namespace :migrations do
    task :new, [:name] do |_t, args|
      if args.name.nil?
        puts 'Name is absent. Please provide a valid name.'
        next
      end

      name = args.name
      id = TimestampedId.new(name:)
      migration = Migrations.new(pg_connection:).generate(id:)

      puts "Migration #{migration.path} has been created."
    end
  end
end
