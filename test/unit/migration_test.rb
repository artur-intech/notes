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
    @migration = Migration.new(path: 'any', pg_connection: 'dummy')
    pg_connection.exec('CREATE TEMP TABLE applied_migrations (id character varying(255) NOT NULL UNIQUE)')
  end

  def test_executes_sql
    create_tmp_file content: 'CREATE TEMP TABLE test()' do |path|
      mig = Migration.new(path:, pg_connection:)
      assert mig.pending?

      mig.apply

      refute mig.pending?
      assert_db_table_exists :test
    end
  end

  def test_equality
    one = Migration.new(path: '/one', pg_connection: 'dummy')
    two = Migration.new(path: '/two', pg_connection: 'dummy')

    assert_equal one, one
    refute_equal one, two
    refute_equal one, {}
  end

  def test_inspect
    assert_equal '1234_test', Migration.new(path: '1234_test.sql', pg_connection: 'dummy').inspect
  end

  def test_sorts_by_path
    third = Migration.new(path: '3_test.sql', pg_connection: 'dummy')
    first = Migration.new(path: '1_test.sql', pg_connection: 'dummy')
    second = Migration.new(path: '2_test.sql', pg_connection: 'dummy')
    assert_equal [first, second, third], [third, first, second].sort
  end

  def test_to_s
    path = '1234_test.sql'
    assert_equal path, Migration.new(path:, pg_connection: 'dummy').to_s
  end

  def test_empty_file
    create_tmp_file content: '' do |path|
      error = assert_raises Migration::InvalidMigrationError do
        Migration.new(path:, pg_connection: 'dummy').apply
      end
      assert_equal 'Empty file', error.message
    end
  end

  def test_invalid_sql
    create_tmp_file content: 'invalid sql' do |path|
      assert_raises Migration::InvalidMigrationError do
        Migration.new(path:, pg_connection:).apply
      end
    end
  end

  def test_invalid_filename
    error = assert_raises Migration::InvalidMigrationError do
      Migration.new(path: 'invalid.sql', pg_connection: 'dummy').pending?
    end
    assert_equal 'Invalid filename', error.message
  end
end
