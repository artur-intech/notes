# frozen_string_literal: true

require 'test_helper'

class AuthenticationIntegrationTest < IntegrationTestCase
  def test_sign_in
    post '/', { email: user.email, password: right_password }

    assert last_request.env['warden'].authenticated?, 'User must be signed in'
    assert_root_redirect
  end

  def test_sign_out
    login_as user

    get '/sign_out'

    assert last_request.env['warden'].unauthenticated?, 'User must be signed out'
    assert_root_redirect
  end

  def test_nonexistent_email
    post '/', { email: 'nonexistent', password: right_password }

    assert last_request.env['warden'].unauthenticated?, 'User must be signed out'
    assert_response :forbidden
  end
end
