# frozen_string_literal: true

require 'test_helper'

class DbMigrationsNewTest < TestCase
  def test_generates_migration
    create_tmp_dir do |path|
      assert Dir.empty? path
      mute_io { run_task 'test' }
      refute Dir.empty? path
    end
  end

  def test_output
    migration_name = 'test'

    create_tmp_dir do
      assert_output %r{Migration #{Migrations.new(pg_connection:).path}/\d+_#{migration_name}\.sql has been created} do
        run_task migration_name
      end
    end
  end

  def test_no_migration_name
    create_tmp_dir do |path|
      assert_output "Name is absent. Please provide a valid name.\n" do
        run_task nil
      end
      assert Dir.empty?(path), 'Migration must not be generated'
    end
  end

  def run_task(migration_name)
    Rake::Task['db:migrations:new'].execute(Rake::TaskArguments.new([:name], [migration_name]))
  end
end
