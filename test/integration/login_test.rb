require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner.clean
    Capybara.reset!
  end

  test 'login' do
    assert_not page.has_selector? '.fa-power-off'
    login
    assert page.has_selector? '.fa-power-off'
    logout
    assert_not page.has_selector? '.fa-power-off'
  end
end
