# frozen_string_literal: true

class PendingMigrations
  class MigrationsPendingError < StandardError; end

  def initialize(origin)
    @origin = origin
  end

  def apply
    migrations.map(&:apply)
  end

  def ensure_applied
    raise MigrationsPendingError, 'Migrations are pending. Run `rake migrate_db`.' if any?
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
