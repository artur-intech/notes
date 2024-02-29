# frozen_string_literal: true

require 'test_helper'

class NotesTest < SystemTestCase
  def setup
    super
    login_as fixtures[:users][:first]
  end

  def test_adds_new_note
    text = 'new note text'

    visit '/'
    click_button 'new-note-btn'
    fill_in 'text', with: text
    click_button 'Create note'

    assert_text text
  end

  # def test_updates_note
  #   note = fixtures[:notes][:first]
  #   new_text = 'new note text'

  #   visit '/'
  #   click_link "edit-note-link-#{note.id}"
  #   fill_in 'Text', with: new_text
  #   click_button 'Update note'

  #   assert_text new_text
  # end

  # def test_escapes_note_text_when_listing
  #   note = fixtures[:notes][:first]
  #   raw_text = '<b>test</b>'
  #   pg_connection.exec_params('UPDATE notes SET text = $2 WHERE id = $1', [note.id, raw_text])

  #   visit '/'

  #   refute page.html.include?(raw_text)
  # end

  # def test_escapes_note_text_when_editing
  #   note = fixtures[:notes][:first]
  #   raw_text = '<b>test</b>'
  #   pg_connection.exec_params('UPDATE notes SET text = $2 WHERE id = $1', [note.id, raw_text])

  #   visit "/notes/#{note.id}/edit"

  #   refute page.html.include?(raw_text)
  # end

  def test_deletes_note
    note = fixtures[:notes][:first]

    visit '/'
    accept_confirm 'Are you sure?' do
      find(%(.note[data-id="#{note.id}"])).right_click
      find('.menu:last-child').click
    end

    assert_no_text note.text
  end
end
