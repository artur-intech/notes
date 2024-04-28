# frozen_string_literal: true

module Assertions
  def assert_difference(expression, expected = 1, &block)
    original_value = expression.call
    block.call
    new_value = expression.call

    actual = new_value - original_value

    message = %(The expression wasn't changed by #{expected}, but by #{actual})
    assert expected == actual, message
  end

  def assert_change(expression, &block)
    before = expression.call
    block.call
    after = expression.call

    message = %(Must have been changed, but it remained the same)
    assert before != after, message
  end

  def assert_change_to(expression, expected, &block)
    before = expression.call
    refute_equal before, expected

    block.call
    after = expression.call

    message = %(Must have been changed to "#{expected}", but it remained "#{after}")
    assert expected == after, message
  end

  # Minitest already has `assert_same`
  def assert_no_change(expression, message = nil, &)
    assert_no_difference(expression, message, &)
  end

  def assert_no_difference(expression, message = nil, &block)
    original_value = expression.call
    block.call
    new_value = expression.call

    message ||= %(The expression must not be changed, but it changed from "#{original_value}" to "#{new_value}")
    assert original_value == new_value, message
  end

  def assert_json_response(expected_hash)
    assert_equal Rack::Mime.mime_type('.json'), last_response['content-type']

    json_response = JSON.parse(last_response.body, symbolize_names: true)
    assert_equal expected_hash, json_response
  end

  def assert_response(expected)
    actual = Rack::Utils::HTTP_STATUS_CODES[last_response.status].downcase
    assert last_response.public_send("#{expected}?"), "Response must be :#{expected}, but was :#{actual}"
  end

  def assert_array_match(expected, actual)
    msg = %(Arrays must match, but they do not: #{expected.inspect}, #{actual.inspect})

    assert_empty (expected.difference(actual) + actual.difference(expected)), msg
  end

  def assert_root_redirect
    assert_response :redirect
    assert_equal '/', URI(last_response.location).path, 'Response must redirect to the root path'
  end

  def assert_db_table_exists(name, message = nil)
    message ||= "Database table #{name} must exist"
    assert pg_connection.exec("SELECT to_regclass('#{name}')::varchar").getvalue(0, 0), message
  end
end
