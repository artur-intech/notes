# frozen_string_literal: true

require 'test_helper'

class NotesApiTest < IntegrationTestCase
  def setup
    super
    login_as fixtures[:users][:first]
  end

  def test_creates
    assert_equal fixtures[:notes].count, db_note_count
    text = 'note text'
    position = 1

    post('/notes', text:, position:)

    assert last_response.ok?
    assert_json_response
    assert_equal fixtures[:notes].count.next, db_note_count, 'Note must be created'
    assert_equal text, json_response[:text]
    assert_equal position, json_response[:position]
  end

  def test_updates
    note = fixtures[:notes][:first]
    new_text = 'updated text'
    refute_equal new_text, note.text

    patch "/notes/#{note.id}", text: new_text

    assert_equal new_text, pg_connection.exec_params('SELECT text FROM notes WHERE id = $1', [note.id]).getvalue(0, 0)
    assert last_response.ok?
    assert_json_response
    assert_equal PgNote.new(note.id, pg_connection).json_hash, json_response
  end

  def test_deletes
    note = fixtures[:notes][:first]
    assert_equal fixtures[:notes].count, db_note_count

    delete "/notes/#{note.id}"

    assert_equal fixtures[:notes].count - 1, db_note_count, 'Note should be deleted'
    assert last_response.ok?
  end

  def test_swaps
    first = PgNote.new(fixtures[:notes][:first].id, pg_connection)
    second = PgNote.new(fixtures[:notes][:second].id, pg_connection)
    cached_first_position = first.position
    cached_second_position = second.position

    patch "/notes/#{first.id}/swap", { note_id: second.id }

    assert last_response.ok?
    assert_equal cached_second_position, first.position
    assert_equal cached_first_position, second.position
  end

  def test_csp_header
    get '/'

    assert last_response.ok?
    assert_equal "default-src 'self'", last_response.headers['Content-Security-Policy']
  end

  def test_lists
    fixture = fixtures[:notes][:first]

    get '/notes'

    assert last_response.ok?
    assert_json_response
    assert_equal fixtures[:notes].count, json_response.size
    assert_equal PgNote.new(fixture.id, pg_connection).json_hash, json_response[1]
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

  private

  def db_note_count
    pg_connection.exec('SELECT COUNT(*) FROM notes').getvalue(0, 0)
  end
end
