# frozen_string_literal: true

require 'test_helper'

class PgNoteTest < TestCase
  def test_reports_text
    note = fixtures[:notes][:first]
    pg_note = PgNote.new(note.id, pg_connection)
    assert_equal note.text, pg_note.text
  end

  def test_reports_position
    fixture = fixtures[:notes][:first]
    note = PgNote.new(fixture.id, pg_connection)
    assert_equal fixture.position, note.position
  end

  def test_updates_itself
    note = PgNote.new(fixtures[:notes][:first].id, pg_connection)
    new_text = 'new text'

    assert_change_to proc { note.text }, new_text do
      note.update(new_text)
    end
  end

  def test_deletes_itself
    pg_note = PgNote.new(fixtures[:notes][:first].id, pg_connection)

    assert_difference proc { db_note_count }, -1 do
      pg_note.delete
    end
  end

  def test_swaps
    first = PgNote.new(fixtures[:notes][:first].id, pg_connection)
    second = PgNote.new(fixtures[:notes][:second].id, pg_connection)
    original_first_position = first.position
    original_second_position = second.position

    first.swap(second.id)

    assert_equal original_second_position, first.position
    assert_equal original_first_position, second.position
  end

  def test_represents_itself_as_json_hash
    fixture = fixtures[:notes][:first]
    pg_note = PgNote.new(fixture.id, pg_connection)

    actual = pg_note.json_hash

    assert_equal ({ id: fixture.id, text: fixture.text, position: fixture.position }), actual
  end

  def test_represents_itself_as_json
    fixture = fixtures[:notes][:first]
    pg_note = PgNote.new(fixture.id, pg_connection)

    actual = pg_note.json

    assert_equal pg_note.json_hash.to_json, actual
  end

  def test_type_casts_id_to_int
    id_as_str = '1'
    note = PgNote.new(id_as_str, nil)
    assert_equal note.id, 1
  end

  def test_reports_user
    fixture = fixtures[:notes][:first]
    note = PgNote.new(fixture.id, pg_connection)
    assert_equal PgUser.new(fixture.user_id, pg_connection), note.user
  end

  def test_note_not_found
    nonexistent_id = 99
    note = PgNote.new(nonexistent_id, pg_connection)

    assert_raises PgNote::NotFoundError do
      note.user
    end

    assert_raises PgNote::NotFoundError do
      note.update('any')
    end

    assert_raises PgNote::NotFoundError do
      note.delete
    end
  end
end
