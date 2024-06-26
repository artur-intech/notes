# frozen_string_literal: true

require 'test_helper'

class SignUpIntegrationTest < IntegrationTestCase
  def test_valid_email_and_password
    post '/sign_up', { email: valid_email, password: valid_password }

    assert_predicate last_request.env['warden'], :authenticated?, 'User must be signed in'
    assert_root_redirect
  end

  def test_existing_email
    post '/sign_up', { email: user.email, password: valid_password }

    assert_predicate last_request.env['warden'], :unauthenticated?, 'User must not be signed in'
  end

  def test_invalid_email
    assert_raises ArgumentError do
      post '/sign_up', { email: 'invalid', password: valid_password }
    end
  end
end
