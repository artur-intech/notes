# frozen_string_literal: true

require 'test_helper'

class AuthenticationIntegrationTest < IntegrationTestCase
  def test_sign_in
    create_fixtures
    user = fixtures[:users][:first]

    post '/', { email: user.email, password: right_password }

    assert last_request.env['warden'].authenticated?, 'User must be signed in'
    assert_root_redirect
  end

  def test_sign_out
    create_fixtures
    login_as fixtures[:users][:first]

    get '/sign_out'

    refute last_request.env['warden'].authenticated?, 'User must be signed out'
    assert_root_redirect
  end

  def test_nonexistent_email
    post '/', { email: 'nonexistent', password: right_password }

    refute last_request.env['warden'].authenticated?, 'User must be signed out'
    assert last_response.forbidden?
  end

  private

  def assert_root_redirect
    response_code_message = Rack::Utils::HTTP_STATUS_CODES[last_response.status]

    assert last_response.redirect?, "Response must redirect, but is '#{response_code_message}'"
    assert_equal '/', URI(last_response.location).path, 'Response must redirect to the root path'
  end
end
