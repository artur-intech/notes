# frozen_string_literal: true

require 'test_helper'

class PgSchemaTest < Minitest::Test
  def test_generates
    refute_path_exists path
    PgSchema.new(path:, pg_connection:).regenerate
    assert_path_exists path
    refute File.empty?(path)
  ensure
    FileUtils.rm_f path
  end

  def path
    'schema'
  end
end
