# frozen_string_literal: true

require 'test_helper'

class PgNotesTest < TestCase
  def test_adds_new_note
    user = create_user_fixture(tag: 'whatever', email: valid_email, encrypted_password:)

    assert db_note_count.zero?

    pg_notes = PgNotes.new(pg_connection)
    pg_notes.add('whatever', 1, user.id)

    assert_equal 1, db_note_count
  end

  def test_iterates_itself
    create_fixtures
    pg_notes = PgNotes.new(pg_connection)
    assert_equal fixtures[:notes].count, pg_notes.count
  end

  def test_biggest_position_comes_first
    user = create_user_fixture(tag: 'whatever', email: valid_email, encrypted_password:)
    pg_notes = PgNotes.new(pg_connection)
    pg_notes.add('whatever', 1, user.id)
    pg_notes.add('whatever', 3, user.id)
    pg_notes.add('whatever', 2, user.id)
    pg_notes = PgNotes.new(pg_connection)

    actual = pg_notes.collect(&:position)

    assert_equal([3, 2, 1], actual)
  end

  def test_represents_itself_as_json
    create_fixtures
    first_fixture = fixtures[:notes][:first]
    second_fixture = fixtures[:notes][:second]
    pg_notes = PgNotes.new(pg_connection)

    actual = pg_notes.json

    assert_equal [{ id: second_fixture.id, text: second_fixture.text, position: second_fixture.position },
                  { id: first_fixture.id, text: first_fixture.text, position: first_fixture.position }].to_json, actual
  end

  def test_reports_updated_at
    create_fixtures
    first_fixture = fixtures[:notes][:first]
    pg_notes = PgNotes.new(pg_connection)

    actual = pg_notes.updated_at

    assert_equal fixtures[:notes].count, actual.count
    assert_equal ({ id: first_fixture.id, updated_at: first_fixture.updated_at }), actual.first
  end

  private

  def db_note_count
    pg_connection.exec('SELECT COUNT(*) FROM notes').getvalue(0, 0)
  end
end
