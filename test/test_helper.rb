require 'simplecov'
SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
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
  module ActiveRecord
    class FixtureSet
      def self.create_fixtures(fixtures_directory, fixture_set_names, class_names = {}, config = ActiveRecord::Base)
        fixture_set_names = Array(fixture_set_names).map(&:to_s)
        class_names = ClassCache.new class_names, config

        # FIXME: Apparently JK uses this.
        connection = block_given? ? yield : ActiveRecord::Base.connection

        files_to_read = fixture_set_names.reject { |fs_name|
          fixture_is_cached?(connection, fs_name)
        }

        unless files_to_read.empty?
          connection.disable_referential_integrity do
            fixtures_map = {}

            fixture_sets = files_to_read.map do |fs_name|
              klass = class_names[fs_name]
              conn = klass ? klass.connection : connection
              fixtures_map[fs_name] = new( # ActiveRecord::FixtureSet.new
                conn,
                fs_name,
                klass,
                ::File.join(fixtures_directory, fs_name))
            end

            all_loaded_fixtures.update(fixtures_map)

            connection.transaction(:requires_new => true) do
              connection.execute("SET CONSTRAINTS ALL DEFERRED")
              # ================
              # Monkey patch : change, first delete all table, then load data
              # ================
              stash = []
              fixture_sets.each do |fs|
                conn = fs.model_class.respond_to?(:connection) ? fs.model_class.connection : connection
                table_rows = fs.table_rows

                table_rows.keys.each do |table|
                  conn.delete "DELETE FROM #{conn.quote_table_name(table)}", 'Fixture Delete'
                end

                table_rows.each do |fixture_set_name, rows|
                  rows.each do |row|
                    stash << [conn, row, fixture_set_name]
                  end
                end
              end

              stash.each do |e|
                e[0].insert_fixture(e[1], e[2])
              end
              # ================
              # End Monkey patch
              # ================

              # Cap primary key sequences to max(pk).
              if connection.respond_to?(:reset_pk_sequence!)
                fixture_sets.each do |fs|
                  connection.reset_pk_sequence!(fs.table_name)
                end
              end
            end

            cache_fixtures(connection, fixtures_map)
          end
        end
        cached_fixtures(connection, fixture_set_names)
      end
    end
  end
end
