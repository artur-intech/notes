# frozen_string_literal: true

require 'test_helper'

class FakeMigrationTest < Minitest::Test
  include MigrationInterfaceTest

  def setup
    @migration = Migration::Fake.new
  end
end

class MigrationTest < TestCase
  include MigrationInterfaceTest

  def setup
    super
    @migration = Migration.new(path: 'any', pg_connection:)
    pg_connection.exec('CREATE TEMP TABLE applied_migrations (id character varying(255) NOT NULL UNIQUE)')
  end

  def test_executes_sql
    create_file 'CREATE TEMP TABLE test()' do |path|
      mig = Migration.new(path:, pg_connection:)
      assert mig.pending?

      mig.apply

      refute mig.pending?
      assert_db_table_exists :test
    end
  end

  def test_equality
    one = Migration.new(path: '/one', pg_connection: nil)
    two = Migration.new(path: '/two', pg_connection: nil)

    assert_equal one, one
    refute_equal one, two
    refute_equal one, {}
  end

  def test_inspect
    assert_equal '1234_test', Migration.new(path: '1234_test.sql', pg_connection: nil).inspect
  end

  def test_sorts_by_path
    third = Migration.new(path: '3_test.sql', pg_connection:)
    first = Migration.new(path: '1_test.sql', pg_connection:)
    second = Migration.new(path: '2_test.sql', pg_connection:)
    assert_equal [first, second, third], [third, first, second].sort
  end

  def test_to_s
    assert_equal '1234_test', Migration.new(path: '1234_test.sql', pg_connection: nil).to_s
  end

  def test_empty
    create_file '' do |path|
      assert_raises Migration::EmptyMigrationError do
        Migration.new(path:, pg_connection:).apply
      end
    end
  end

  def test_invalid
    create_file 'invalid sql' do |path|
      assert_raises Migration::InvalidMigrationError do
        Migration.new(path:, pg_connection:).apply
      end
    end
  end

  def create_file(contents)
    path = File.join(Dir.tmpdir, 'test.sql')
    FileUtils.touch(path)
    File.write(path, contents)
    yield path
  ensure
    File.delete path
  end
end
