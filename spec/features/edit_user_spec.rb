require 'rails_helper'
require 'capybara_helper'

feature :edit_user do
  fixtures :all

  before :each do
    login
  end

  scenario 'change password' do
    visit edit_user_registration_path
    fill_in 'user[password]', with: 'pwd123456789'
    fill_in 'user[password_confirmation]', with: 'pwd123456789'
    fill_in 'user[current_password]', with: '123456789'
    submit

    logout

    login('u1@plop.com', 'pwd123456789')
    expect(page).to have_selector('.fa-power-off')
  end
end
