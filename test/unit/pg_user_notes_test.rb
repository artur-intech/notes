# frozen_string_literal: true

require 'test_helper'

class PgUserNotesTest < TestCase
  def test_adds_new_note
    original_count = user_notes.size
    pg_notes = PgUserNotes.new(user.id, pg_connection)

    pg_notes.add('whatever', 1)

    assert_equal original_count.next, db_user_note_count
  end

  def test_iterates_itself
    pg_notes = PgUserNotes.new(user.id, pg_connection, proc do |pg_row|
                                                         OpenStruct.new(pg_row.transform_keys(&:to_sym))
                                                       end)
    actual = pg_notes.to_a
    assert_empty user_notes.difference(actual)
  end

  def test_biggest_position_comes_first
    pg_connection.exec('TRUNCATE notes')
    pg_notes = PgUserNotes.new(user.id, pg_connection)
    pg_notes.add('whatever', 1)
    pg_notes.add('whatever', 3)
    pg_notes.add('whatever', 2)
    pg_notes = PgUserNotes.new(user.id, pg_connection)

    actual = pg_notes.collect(&:position)

    assert_equal([3, 2, 1], actual)
  end

  def test_represents_itself_as_json
    pg_notes = PgUserNotes.new(user.id, pg_connection, proc do |pg_row|
      OpenStruct.new(json_hash: { id: pg_row['id'] })
    end)

    actual = pg_notes.json

    assert_equal user_notes.reverse.map { |note| { id: note.id } }.to_json, actual
  end

  def test_reports_updated_at
    first_fixture = fixtures[:notes][:first]
    pg_notes = PgUserNotes.new(user.id, pg_connection)

    actual = pg_notes.updated_at

    assert_equal fixtures[:notes].count, actual.count
    assert_equal ({ id: first_fixture.id, updated_at: first_fixture.updated_at }), actual.first
  end

  def test_notes_from_other_users_must_be_absent
    other_user_note_id = fixtures[:notes][:third].id
    actual = PgUserNotes.new(user.id, pg_connection).to_a.collect(&:id)
    refute_includes actual, other_user_note_id
  end
end
