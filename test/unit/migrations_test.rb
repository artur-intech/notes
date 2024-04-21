# frozen_string_literal: true

require 'test_helper'

class MigrationsTest < TestCase
  def test_returns_migrations_in_chronological_reversed_order
    create_tmp_dir do |path|
      FileUtils.touch(File.join(path, '3.sql'))
      FileUtils.touch(File.join(path, '1.sql'))
      FileUtils.touch(File.join(path, '2.sql'))
      expected = [Migration.new(path: File.join(path, '3.sql'), pg_connection: 'dummy'),
                  Migration.new(path: File.join(path, '2.sql'), pg_connection: 'dummy'),
                  Migration.new(path: File.join(path, '1.sql'), pg_connection: 'dummy')]

      actual = Migrations.new(path:, pg_connection: 'dummy').to_a

      assert_equal expected, actual
    end
  end

  def test_generates
    create_tmp_dir do |path|
      filepath = File.join(path, 'test.sql')

      refute_path_exists filepath

      actual = Migrations.new(path:, pg_connection: 'dummy').generate(id: 'test')

      assert_path_exists filepath
      assert_equal Migration.new(path: filepath, pg_connection: 'dummy'), actual
    end
  end

  def test_default_path
    assert_equal 'db/migrations', Migrations.new(pg_connection: 'dummy').path
  end
end
