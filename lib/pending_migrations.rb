# frozen_string_literal: true

class PendingMigrations
  class MigrationsPendingError < StandardError; end

  def initialize(origin)
    @origin = origin
  end

  def apply
    migrations.each do |migration|
      migration.apply
      yield migration
    end
  end

  def ensure_applied
    raise MigrationsPendingError, 'Migrations are pending. Run `rake migrate_db`.' if any?
  end

  def none?
    !any?
  end

  private

  attr_reader :origin

  def any?
    migrations.any?
  end

  def migrations
    origin.select(&:pending?)
  end
end
