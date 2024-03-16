# frozen_string_literal: true

require 'test_helper'

class PgUserNotesTest < TestCase
  def test_adds_new_note
    notes = PgUserNotes.new(user.id, pg_connection)
    assert_difference proc { db_user_note_count } do
      assert_equal fixtures[:notes].size.next, notes.add('any', 1)
    end
  end

  def test_iterates_itself
    pg_notes = PgUserNotes.new(user.id, pg_connection, proc do |id|
                                                         id
                                                       end)
    assert_empty user_notes.map(&:id).difference(pg_notes.fetch)
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
end
