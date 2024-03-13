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
    note = fixtures[:notes][:first]
    new_text = 'new text'
    refute_equal new_text, note.text
    assert note.updated_at
    pg_note = PgNote.new(note.id, pg_connection)

    pg_note.update(new_text)

    assert_equal new_text, pg_note.text
    refute_equal note.updated_at,
                 pg_connection.exec_params('SELECT updated_at FROM notes WHERE id = $1', [note.id]).getvalue(0, 0),
                 'Last update date must be updated'
  end

  def test_deletes_itself
    note = fixtures[:notes][:first]
    pg_note = PgNote.new(note.id, pg_connection)

    pg_note.delete

    assert pg_connection.exec_params('SELECT id FROM notes WHERE id = $1', [note.id]).num_tuples.zero?
  end

  def test_keeps_others_intact_when_deleting
    note = fixtures[:notes][:first]
    other = fixtures[:notes][:second]
    pg_note = PgNote.new(note.id, pg_connection)

    pg_note.delete

    refute pg_connection.exec_params('SELECT id FROM notes WHERE id = $1', [other.id]).num_tuples.zero?
  end

  def test_swaps
    first = PgNote.new(fixtures[:notes][:first].id, pg_connection)
    second = PgNote.new(fixtures[:notes][:second].id, pg_connection)
    cached_first_position = first.position
    cached_second_position = second.position

    first.swap(second.id)

    assert_equal cached_second_position, first.position
    assert_equal cached_first_position, second.position
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
end
