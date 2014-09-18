require 'rails_helper'
require 'capybara_helper'

feature :login do
  fixtures :all

  before :each do
  end

  scenario 'login' do
    login
    expect(page).to have_selector('.fa-power-off')
    logout
    expect(page).to_not have_selector('.fa-power-off')
  end
end
