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

  private

  def assert_root_redirect
    assert last_response.redirect?, 'Response must redirect'
    assert_equal '/', URI(last_response.location).path, 'Response must redirect to the root path'
  end
end