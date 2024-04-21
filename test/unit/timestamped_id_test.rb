# frozen_string_literal: true

require 'test_helper'

class TimestampedIdTest < TestCase
  def test_behaves_like_string
    clock = Clock::Fake.new

    assert_equal "#{clock.now.to_i}_test", TimestampedId.new(name: 'test', clock:).to_str
  end

  def test_represents_as_string
    clock = Clock::Fake.new

    assert_equal "#{clock.now.to_i}_test", TimestampedId.new(name: 'test', clock:).to_s
  end
end
