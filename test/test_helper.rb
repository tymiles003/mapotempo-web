require 'capybara/rails'

require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionController::TestCase
  include Devise::TestHelpers
end

class ActionDispatch::IntegrationTest
  # Make the Capybara DSL available in all integration tests
  include Capybara::DSL

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
        page.driver.accept_confirms!
      elsif Capybara.javascript_driver == :selenium
        page.driver.browser.switch_to.alert.accept
      end
    end
  end
end

Capybara.configure do |config|
  config.javascript_driver = :webkit
  config.current_driver = Capybara.javascript_driver
end

if ActiveRecord::ConnectionAdapters.const_defined?(:PostgreSQLAdapter)
  class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    alias_method :old_delete, :delete
    alias_method :old_insert_fixture, :insert_fixture

    def delete(*args)
      @defered |= defered
      old_delete(*args)
    end

    def insert_fixture(*args)
      @defered |= defered
      old_insert_fixture(*args)
    end

    private
      def defered
        execute("SET CONSTRAINTS ALL DEFERRED")
      end
  end
end
