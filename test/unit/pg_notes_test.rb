# frozen_string_literal: true

require 'test_helper'

class PgNotesTest < TestCase
  def test_adds_new_note
    user_id = fixtures[:users][:first].id
    original_count = fixtures[:notes].size

    pg_notes = PgNotes.new(pg_connection)
    pg_notes.add('whatever', 1, user_id)

    assert_equal original_count.next, db_note_count
  end

  def test_iterates_itself
    pg_notes = PgNotes.new(pg_connection)
    assert_equal fixtures[:notes].count, pg_notes.count
  end

  def test_biggest_position_comes_first
    user_id = fixtures[:users][:first].id
    pg_connection.exec('TRUNCATE notes')
    pg_notes = PgNotes.new(pg_connection)
    pg_notes.add('whatever', 1, user_id)
    pg_notes.add('whatever', 3, user_id)
    pg_notes.add('whatever', 2, user_id)
    pg_notes = PgNotes.new(pg_connection)

    actual = pg_notes.collect(&:position)

    assert_equal([3, 2, 1], actual)
  end

  def test_represents_itself_as_json
    first_fixture = fixtures[:notes][:first]
    second_fixture = fixtures[:notes][:second]
    pg_notes = PgNotes.new(pg_connection)

    actual = pg_notes.json

    assert_equal [{ id: second_fixture.id, text: second_fixture.text, position: second_fixture.position },
                  { id: first_fixture.id, text: first_fixture.text, position: first_fixture.position }].to_json, actual
  end

  def test_reports_updated_at
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
