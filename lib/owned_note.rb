# frozen_string_literal: true

require 'delegate'

class OwnedNote < SimpleDelegator
  class OwnershipError < StandardError; end

  def initialize(user:, note:)
    super(note)
    @user = user
    @note = note
  end

  def update(text:)
    ensure_owned(note)
    note.update(text)
  end

  def delete
    ensure_owned(note)
    note.delete
  end

  def swap(target_note:)
    ensure_owned(note)
    ensure_owned(target_note)
    note.swap(target_note.id)
  end

  private

  attr_reader :user, :note

  def ensure_owned(note)
    raise OwnershipError if note.user != user
  end
end
