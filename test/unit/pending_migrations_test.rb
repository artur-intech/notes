# frozen_string_literal: true

require 'test_helper'

class PendingMigrationsTest < Minitest::Test
  def test_applies_pending
    mock = Minitest::Mock.new(Migration::Fake.new(pending: true))
    mock.expect(:apply, nil)
    applied_migrations = []

    PendingMigrations.new([mock]).apply do |migration|
      applied_migrations << migration
    end

    assert_mock mock
    assert_equal [mock], applied_migrations
  end

  def test_skips_applied
    mig = Migration::Fake.new(pending: false)
    PendingMigrations.new([mig]).apply

    refute_predicate mig, :applied?, 'Must skip applied migration'
  end

  def test_ensures_applied
    error = assert_raises PendingMigrations::MigrationsPendingError do
      PendingMigrations.new([Migration::Fake.new(pending: true)]).ensure_applied
    end
    assert_equal 'Migrations are pending. Run `rake migrate_db`.', error.message
  end

  def test_reports_when_none
    migrations = PendingMigrations.new([Migration::Fake.new(pending: true)])

    refute_predicate migrations, :none?

    migrations = PendingMigrations.new([Migration::Fake.new(pending: false)])

    assert_predicate migrations, :none?
  end
end
