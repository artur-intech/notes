# frozen_string_literal: true

require 'test_helper'

class PgUserNotesTest < TestCase
  def test_adds_new_note
    notes = PgUserNotes.new(user.id, pg_connection)

    assert_difference proc { db_user_note_count } do
      assert_equal fixtures[:notes].size.next, notes.add('any', 1)
    end

    error = assert_raises(ArgumentError) { notes.add(nil, 1) }
    assert_equal 'Text cannot be nil', error.message

    error = assert_raises(ArgumentError) { notes.add('', 1) }
    assert_equal 'Text cannot be empty', error.message

    error = assert_raises(ArgumentError) { notes.add('any', -1) }
    assert_equal 'Position cannot be negative', error.message
  end

  def test_fetches
    expected = user_notes.map(&:id)
    actual = PgUserNotes.new(user.id, pg_connection, proc { |id| id }).fetch

    assert_array_match expected, actual
  end

  def test_biggest_position_comes_first
    pg_connection.exec('TRUNCATE notes')
    pg_notes = PgUserNotes.new(user.id, pg_connection)
    pg_notes.add('whatever', 1)
    pg_notes.add('whatever', 3)
    pg_notes.add('whatever', 2)
    pg_notes = PgUserNotes.new(user.id, pg_connection)

    actual = pg_notes.fetch.collect(&:position)

    assert_equal([3, 2, 1], actual)
  end

  def test_represents_itself_as_json
    pg_notes = PgUserNotes.new(user.id, pg_connection, proc do |id|
      OpenStruct.new(json_hash: { id: })
    end)

    actual = pg_notes.json

    assert_equal user_notes.map { |note| { id: note.id } }.to_json, actual
  end

  def test_notes_from_other_users_must_be_absent
    other_user_note_id = fixtures[:notes][:third].id
    actual = PgUserNotes.new(user.id, pg_connection).fetch.collect(&:id)

    refute_includes actual, other_user_note_id
  end

  def test_reports_ids
    assert_array_match user_notes.collect(&:id), PgUserNotes.new(user.id, pg_connection).ids
  end
end
