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

    assert_difference proc { db_user_note_count } do
      post('/notes', text:, position:)
    end
    assert_response :ok
    assert_json_response(PgNote.new(fixtures[:notes].size.next, pg_connection).json_hash)
  end

  def test_updates
    note = PgNote.new(user_notes.first.id, pg_connection)
    new_text = 'new'

    assert_change proc {
                    pg_connection.exec_params('SELECT updated_at FROM notes WHERE id = $1', [note.id]).getvalue(0, 0)
                  } do
      assert_change_to proc { note.text }, new_text do
        patch "/notes/#{note.id}", text: new_text
      end
    end

    assert_response :ok
    assert_json_response(note.json_hash)
  end

  def test_deletes
    note = user_notes.first

    assert_difference proc { db_user_note_count }, -1 do
      delete "/notes/#{note.id}"
    end
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
    expected = user_notes.map do |note|
      PgNote.new(note.id, pg_connection).json_hash
    end
    assert_json_response(expected)
  end

  def test_prohibit_anonymous_user
    logout

    get '/', nil, 'HTTP_ACCEPT' => Rack::Mime.mime_type('.html')
    assert_response :ok
    assert_match Rack::Mime.mime_type('.html'), last_response.content_type
    refute_empty last_response.body

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

    get '/', nil, 'HTTP_ACCEPT' => Rack::Mime.mime_type('.json')
    assert last_response.forbidden?
    assert_empty last_response.body
  end

  def test_non_owned_note_cannot_be_updated
    new_text = 'new'
    note = non_owned_note
    refute_equal new_text, note.text

    assert_no_change proc { note.text } do
      patch "/notes/#{note.id}", text: new_text
    end
    assert_response :not_found
  end

  def test_non_owned_note_cannot_be_deleted
    note = non_owned_note

    assert_no_difference proc { db_note_count }, 'Note must not be deleted' do
      delete "/notes/#{note.id}"
    end
    assert_response :not_found
  end

  def test_non_owned_note_cannot_be_swapped
    note = non_owned_note
    target_note = PgNote.new(fixtures[:notes][:first].id, pg_connection)
    refute_equal note.id, target_note.id
    refute_equal note.position, target_note.position

    assert_no_change proc { note.position } do
      patch "/notes/#{note.id}/swap", note_id: target_note.id
    end
    assert_response :not_found
  end

  def test_nonexistent_note
    patch '/notes/nonexistent'
    assert_response :not_found

    delete '/notes/nonexistent'
    assert_response :not_found

    patch '/notes/nonexistent/swap'
    assert_response :not_found
  end

  private

  def non_owned_note
    note = PgNote.new(fixtures[:notes][:third].id, pg_connection)
    refute_equal note.user, user
    note
  end
end
