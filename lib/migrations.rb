# frozen_string_literal: true

class Migrations
  attr_reader :path

  include Enumerable

  def initialize(pg_connection:, path: 'db/migrations', migration_by_path: proc { |migpath|
                                                                             Migration.new(path: migpath,
                                                                                           pg_connection:)
                                                                           })
    @path = path
    @migration_by_path = migration_by_path
  end

  def each(&)
    migrations = Dir.new(path).children.map { |p| migration_by_path.call(File.join(path, p)) }
    migrations.sort.each(&)
  end

  def generate(id:)
    filepath = File.join(path, "#{id}.sql")
    FileUtils.touch(filepath)
    migration_by_path.call(filepath)
  end

  def create_path
    FileUtils.mkdir_p path
  end

  private

  attr_reader :migration_by_path
end
