# frozen_string_literal: true

desc 'Apply pending migrations'
namespace :db do
  namespace :migrations do
    task :apply do
      PendingMigrations.new(Migrations.new('db/migrations')).apply
      PgSchema.new('db/schema.sql').generate
    end
  end
end
