
Capybara.configure do |config|
  config.javascript_driver = :webkit
end

RSpec.configure do |config|
  def submit
    first('[type=submit]').click
  end

  def login(user='u1@plop.com', password='123456789')
    visit new_user_session_path
    fill_in 'user[email]', with: user
    fill_in 'user[password]', with: password
    submit
  end

  def logout
    o = first('a[href="/users/sign_out"]')
    o.click if o
  end

  def alert_accept
    if Capybara.current_driver == Capybara.javascript_driver
      if Capybara.javascript_driver == :webkit
        page.driver.accept_js_confirms!
      elsif Capybara.javascript_driver == :selenium
        page.driver.browser.switch_to.alert.accept
      end
    end
  end
end
