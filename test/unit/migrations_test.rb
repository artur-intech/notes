# frozen_string_literal: true

require 'test_helper'

class MigrationsTest < TestCase
  def test_returns_migrations_in_chronological_reversed_order
    create_tmp_dir do |path|
      FileUtils.touch('3.sql')
      FileUtils.touch('1.sql')
      FileUtils.touch('2.sql')
      expected = [Migration.new(path: File.join(path, '3.sql'), pg_connection:),
                  Migration.new(path: File.join(path, '2.sql'), pg_connection:),
                  Migration.new(path: File.join(path, '1.sql'), pg_connection:)]

      actual = Migrations.new(path:, pg_connection:).to_a

      assert_equal expected, actual
    end
  end

  def test_generates
    create_tmp_dir do |path|
      migpath = File.join(path, 'test.sql')
      refute_path_exists migpath

      actual = Migrations.new(path:, pg_connection:).generate(id: 'test')

      assert_path_exists migpath
      assert_equal Migration.new(path: migpath, pg_connection:), actual
    end
  end
end
