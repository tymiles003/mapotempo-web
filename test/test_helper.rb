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

if ActiveRecord::ConnectionAdapters.const_defined?(:PostgreSQLAdapter)
  class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    alias_method :old_delete, :delete
    alias_method :old_insert_fixture, :insert_fixture

    def delete(*args)
      defered
      old_delete(*args)
    end

    def insert_fixture(*args)
      defered
      old_insert_fixture(*args)
    end

    def disable_referential_integrity
      defered
      yield
    end

    private
      def defered
        execute("SET CONSTRAINTS ALL DEFERRED")
      end
  end
end
