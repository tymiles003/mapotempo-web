require 'test_helper'

class EditUserTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner.clean
    Capybara.reset!
    login
  end

  test 'change password' do
    visit edit_user_registration_path
    fill_in 'user[password]', with: 'pwd123456789'
    fill_in 'user[password_confirmation]', with: 'pwd123456789'
    fill_in 'user[current_password]', with: '123456789'
    submit

    logout

    login('u1@plop.com', 'pwd123456789')
    assert page.has_selector? '.icon-off'
  end
end
