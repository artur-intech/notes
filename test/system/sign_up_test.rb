# frozen_string_literal: true

require 'test_helper'

class SignUpTest < SystemTestCase
  def test_valid_email_and_password
    email = valid_email

    visit '/'
    click_link 'Sign up'

    fill_in 'email', with: email
    fill_in 'password', with: valid_password
    click_button 'Sign up'

    assert_text email
  end

  def test_existing_user
    password = 'any'

    visit '/'
    click_link 'Sign up'

    fill_in 'email', with: user.email
    fill_in 'password', with: password
    click_button 'Sign up'

    assert_text 'Email is already taken.'
    assert_field 'email', with: user.email
    assert_field 'password', with: password
  end
end
