# frozen_string_literal: true

require 'test_helper'

class PgNotesTest < TestCase
  def test_adds_new_note
    assert db_note_count.zero?

    pg_notes = PgNotes.new(pg_connection)
    pg_notes.add('whatever', 1)

    assert_equal 1, db_note_count
  end

  def test_iterates_itself
    create_fixtures
    pg_notes = PgNotes.new(pg_connection)
    assert_equal fixtures[:notes].count, pg_notes.count
  end

  def test_biggest_position_comes_first
    pg_notes = PgNotes.new(pg_connection)
    pg_notes.add('whatever', 1)
    pg_notes.add('whatever', 3)
    pg_notes.add('whatever', 2)
    pg_notes = PgNotes.new(pg_connection)

    actual = pg_notes.collect(&:position)

    assert_equal([3, 2, 1], actual)
  end

  private

  def teardown
    clean_up_db
  end

  def db_note_count
    pg_connection.exec('SELECT COUNT(*) FROM notes').getvalue(0, 0)
  end
end
