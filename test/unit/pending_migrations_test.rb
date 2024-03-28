# frozen_string_literal: true

require 'test_helper'

class PendingMigrationsTest < TestCase
  def test_applies_pending
    mock = Minitest::Mock.new(Migration::Fake.new(pending: true))
    mock.expect(:apply, nil)

    PendingMigrations.new([mock]).apply

    assert_mock mock
  end

  def test_skips_applied
    mig = Migration::Fake.new(pending: false)
    PendingMigrations.new([mig]).apply
    refute mig.applied?, 'Must skip applied migration'
  end

  def test_ensures_applied
    error = assert_raises PendingMigrations::MigrationsPendingError do
      PendingMigrations.new([Migration::Fake.new(pending: true)]).ensure_applied
    end
    assert_equal 'Migrations are pending. Run `rake migrate_db`.', error.message
  end
end
