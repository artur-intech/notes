# frozen_string_literal: true

class Migrations
  include Enumerable

  def initialize(path:, pg_connection:, migration_by_path: proc { |migpath|
                                                             Migration.new(path: migpath, pg_connection:)
                                                           })
    @path = path
    @migration_by_path = migration_by_path
  end

  def each(&)
    migrations = Dir.new(path).children.map { |p| migration_by_path.call(File.join(path, p)) }
    migrations.sort.reverse.each(&)
  end

  def generate(id:)
    filepath = File.join(path, "#{id}.sql")
    FileUtils.touch(filepath)
    migration_by_path.call(filepath)
  end

  attr_reader :path, :migration_by_path
end
