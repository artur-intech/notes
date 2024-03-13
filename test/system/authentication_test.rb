# frozen_string_literal: true

require 'test_helper'

class AuthenticationSystemTest < SystemTestCase
  def test_sign_in
    visit '/'
    fill_in 'email', with: user.email
    fill_in 'password', with: right_password
    click_button 'Sign in'

    refute_text 'Please sign in'
    assert_text user.email
    assert_css 'body.page-notes'
  end

  def test_sign_out
    login_as user

    visit '/'
    click_link 'Sign out'

    assert_text 'Please sign in'
    assert_button 'Sign in'
    assert_css 'body.page-unauthenticated'
  end
end
