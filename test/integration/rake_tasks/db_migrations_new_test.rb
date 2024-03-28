# frozen_string_literal: true

require 'test_helper'

class DbMigrationsNewTest < TestCase
  def test_creates_empty_migration
    create_dir do |path|
      assert Dir.empty? path
      capture_io { run_task }
      refute Dir.empty? path
    end
  end

  def test_output
    ensure_file_system_isolated do
      assert_output %r{Migration db/migrations/\d+_test\.sql has been created} do
        run_task
      end
    end
  end

  private

  def run_task
    Rake::Task['db:migrations:new'].execute(Rake::TaskArguments.new([:name], ['test']))
  end

  def create_dir
    Dir.mktmpdir do |path|
      Dir.chdir path do
        path = File.join(path, 'db/migrations')
        FileUtils.mkdir_p path
        yield path
      end
    end
  end
end
