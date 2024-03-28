# frozen_string_literal: true

class TimestampedId
  def initialize(name:, clock: Clock::System.new)
    @name = name
    @clock = clock
  end

  def to_str
    id
  end

  def to_s
    to_str
  end

  private

  attr_reader :name, :clock

  def id
    "#{timestamp}_#{name}"
  end

  def timestamp
    clock.now.to_i
  end
end
