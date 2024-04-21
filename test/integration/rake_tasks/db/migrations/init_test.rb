# frozen_string_literal: true

require 'test_helper'

class DbMigrationsInitTest < TestCase
  def setup
    super
    # Skip 'table "applied_migrations" does not exist, skipping' notice
    pg_connection.exec('set client_min_messages = warning; DROP TABLE IF EXISTS applied_migrations')
  end

  def test_creates_db_table
    create_tmp_dir do
      mute_io { run_task }

      assert_db_table_exists :applied_migrations
    end
  end

  def test_creates_dir
    create_tmp_dir do
      FileUtils.rm_rf 'db/migrations'
      mute_io { run_task }

      assert_path_exists 'db/migrations'
    end
  end

  def test_generates_schema
    create_tmp_dir do
      refute_path_exists 'db/schema.sql'
      mute_io { run_task }

      assert_path_exists 'db/schema.sql'
    end
  end

  def test_output
    create_tmp_dir do
      assert_output "Database migrations have been initialized. Generate one using `rake db:migrations:new[name]`.\n" do
        run_task
      end
    end
  end

  def run_task
    Rake::Task['db:migrations:init'].execute
  end
end
