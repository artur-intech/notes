# frozen_string_literal: true

require 'test_helper'

class PgSchemaTest < TestCase
  def test_generates
    create_tmp_dir do
      schema = PgSchema.new(pg_connection:)
      refute_path_exists schema.path

      schema.generate

      assert_path_exists schema.path
      refute File.empty?(schema.path)
    end
  end

  def test_regenerates
    create_tmp_file do |path|
      assert_change proc { File.mtime(path) } do
        PgSchema.new(path:, pg_connection:).regenerate
      end
    end
  end

  def test_default_path
    assert_equal 'db/schema.sql', PgSchema.new(pg_connection:).path
  end
end
