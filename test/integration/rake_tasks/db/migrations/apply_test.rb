# frozen_string_literal: true

require 'test_helper'

class DbMigrationsApplyTest < TestCase
  def test_applies_pending_migrations
    create_tmp_dir do |dirpath|
      create_tmp_file dir: dirpath, content: 'CREATE TABLE test()' do
        mute_io { run_task }
        assert_db_table_exists :test, 'Migration must be applied'
      end
    end
  end

  def test_no_pending
    create_tmp_dir do
      assert_output "There are no pending migrations.\n" do
        run_task
      end
    end
  end

  def test_regenerates_schema
    create_tmp_dir do |dirpath|
      create_tmp_file dir: dirpath do
        refute_path_exists 'db/schema.sql'
        mute_io { run_task }
        assert_path_exists 'db/schema.sql'
      end
    end
  end

  def test_output
    create_tmp_dir do |dirpath|
      create_tmp_file dir: dirpath do |_path, name|
        assert_output(/Migration #{File.join(Migrations.new(pg_connection:).path, name)} has been applied/) do
          run_task
        end
      end
    end
  end

  def test_schema_is_kept_intact_when_migration_is_invalid
    create_tmp_dir do |dirpath|
      schema_path = PgSchema.new(pg_connection: 'dummy').path
      FileUtils.touch(schema_path)

      create_tmp_file dir: dirpath, content: 'invalid sql' do
        assert_no_change proc { File.mtime(schema_path).inspect } do
          assert_output(/Migration is invalid/) do
            run_task
          end
        end
      end
    end
  end

  def teardown
    super
    pg_connection.exec('TRUNCATE applied_migrations RESTART IDENTITY CASCADE')
    # Skip 'table "applied_migrations" does not exist, skipping' notice
    pg_connection.exec('set client_min_messages = warning; DROP TABLE IF EXISTS test')
  end

  def run_task
    Rake::Task['db:migrations:apply'].execute
  end
end
