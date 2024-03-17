# frozen_string_literal: true

require 'test_helper'

class FakeNote
  attr_reader :user, :id

  def initialize(user:)
    @user = user
    @id = 1
  end

  def swap(target_note); end
end

class OwnedNoteTest < TestCase
  def test_delegates_update_call
    text = 'any'
    user = PgUser.new(1, nil)
    note = FakeNote.new(user:)
    mock = Minitest::Mock.new(note)
    mock.expect(:update, nil, [text])

    p_note = OwnedNote.new(user:, note: mock)
    p_note.update(text:)

    assert_mock mock
  end

  def test_delegates_delete_call
    user = PgUser.new(1, nil)
    note = FakeNote.new(user:)
    mock = Minitest::Mock.new(note)
    mock.expect(:delete, nil)

    p_note = OwnedNote.new(user:, note: mock)
    p_note.delete

    assert_mock mock
  end

  def test_delegates_wrap_call
    user = PgUser.new(1, nil)
    note = FakeNote.new(user:)
    target_note = note.dup
    mock = Minitest::Mock.new(note)
    mock.expect(:swap, nil, [target_note.id])

    p_note = OwnedNote.new(user:, note: mock)
    p_note.swap(target_note:)

    assert_mock mock
  end

  def test_ownership_error
    me = PgUser.new(1, nil)
    stranger = PgUser.new(2, nil)
    my_note = FakeNote.new(user: me)
    stranger_note = FakeNote.new(user: stranger)

    personal_note = OwnedNote.new(user: me, note: stranger_note)

    assert_ownership_error { personal_note.update(text: 'any') }
    assert_ownership_error { personal_note.delete }
    assert_ownership_error { personal_note.swap(target_note: my_note) }
    assert_ownership_error do
      personal_note = OwnedNote.new(user: me, note: my_note)
      personal_note.swap(target_note: stranger_note)
    end
  end

  private

  def assert_ownership_error(&)
    assert_raises(OwnedNote::OwnershipError, &)
  end
end
