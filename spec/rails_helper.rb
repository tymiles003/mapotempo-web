# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
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
