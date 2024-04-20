# frozen_string_literal: true

require 'test_helper'

class NotesTest < SystemTestCase
  def setup
    super
    login_as user
  end

  def test_adds_new_note
    text = 'new note text'

    visit '/'
    click_on 'new-note-btn'
    fill_in 'text', with: text
    click_on 'Create note'

    assert_text text
  end

  def test_updates_note
    note = fixtures[:notes][:first]
    new_text = 'new'

    visit '/'
    find(%(.note[data-id="#{note.id}"])).right_click
    find('.menu .item:first-child').click
    page.driver.active_element.native.send_keys new_text
    blur

    assert_equal "#{note.text}#{new_text}", find(%(.note[data-id="#{note.id}"])).text
  end

  def test_deletes_note
    note = fixtures[:notes][:first]

    visit '/'
    accept_confirm 'Are you sure?' do
      find(%(.note[data-id="#{note.id}"])).right_click
      find('.menu:last-child').click
    end

    assert_no_text note.text
  end

  def blur
    find('body').click
  end
end
