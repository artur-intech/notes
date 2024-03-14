# frozen_string_literal: true

require 'test_helper'

class NotesApiTest < IntegrationTestCase
  def setup
    super
    login_as user
  end

  def test_creates
    text = 'note text'
    position = 1

    post('/notes', text:, position:)

    assert_response :ok
    assert_json_response(PgNote.new(fixtures[:notes].size.next, pg_connection).json_hash)
    assert_equal user_notes.size.next, db_user_note_count, 'Note must be created'
  end

  def test_updates
    note = PgNote.new(user_notes.first.id, pg_connection)
    new_text = 'new'
    refute_equal new_text, note.text

    patch "/notes/#{note.id}", text: new_text

    assert_equal new_text, note.text
    assert_response :ok
    assert_json_response(note.json_hash)
  end

  def test_deletes
    note = user_notes.first

    delete "/notes/#{note.id}"

    assert_equal user_notes.size - 1, db_user_note_count, 'Note must be deleted'
    assert_response :ok
  end

  def test_swaps
    first = PgNote.new(user_notes[0].id, pg_connection)
    second = PgNote.new(user_notes[1].id, pg_connection)
    original_first_position = first.position
    original_second_position = second.position

    patch "/notes/#{first.id}/swap", { note_id: second.id }

    assert_response :ok
    assert_equal original_second_position, first.position
    assert_equal original_first_position, second.position
  end

  def test_csp_header
    get '/'

    assert_response :ok
    assert_equal "default-src 'self'", last_response.headers['Content-Security-Policy']
  end

  def test_lists
    get '/notes'

    assert_response :ok
    expected = user_notes.reverse.map do |note|
      PgNote.new(note.id, pg_connection).json_hash
    end
    assert_json_response(expected)
  end

  def test_prohibit_anonymous_user
    logout

    get '/'
    assert last_response.forbidden?, 'Anonymous user must not be able to access GET /'

    get '/sse'
    assert last_response.forbidden?, 'Anonymous user must not be able to access GET /sse'

    get '/notes'
    assert last_response.forbidden?, 'Anonymous user must not be able to access GET /notes'

    post '/notes'
    assert last_response.forbidden?, 'Anonymous user must not be able to access POST /notes'

    patch '/notes/any'
    assert last_response.forbidden?, 'Anonymous user must not be able to access PATCH /notes/:id'

    delete '/notes/any'
    assert last_response.forbidden?, 'Anonymous user must not be able to access DELETE /notes/:id'

    patch '/notes/any/swap'
    assert last_response.forbidden?, 'Anonymous user must not be able to access PATCH /notes/:id/swap'
  end

  def test_non_owned_note_cannot_be_updated
    note = non_owned_note
    original_text = note.text

    patch "/notes/#{note.id}", text: 'new'

    assert_equal original_text, note.text, 'Note text must be kept intact'
    assert_response :not_found
  end

  def test_non_owned_note_cannot_be_deleted
    note = non_owned_note

    delete "/notes/#{note.id}"

    assert pg_connection.exec_params('SELECT id FROM notes WHERE id = $1', [note.id]).num_tuples.nonzero?,
           'Note must not be deleted'
    assert_response :not_found
  end

  def test_non_owned_note_cannot_be_swapped
    note = non_owned_note
    original_position = note.position

    patch "/notes/#{note.id}/swap", note_id: note.id

    assert_equal original_position, note.position, 'Note position must be kept intact'
    assert_response :not_found
  end

  def non_owned_note
    note = PgNote.new(fixtures[:notes][:third].id, pg_connection)
    refute_equal note.user, user
    note
  end
end
