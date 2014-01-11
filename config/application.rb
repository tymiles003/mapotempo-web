require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Mapotempo
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.assets.initialize_on_precompile = true
  end
end

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  class_attr_index = html_tag.index 'class="'

  if class_attr_index
    html_tag.insert class_attr_index+7, 'ui-state-error '
  else
    html_tag.insert html_tag.index('>'), ' class="ui-state-error"'
  end
end

module ActiveRecord
  module Validations
    class AssociatedBubblingValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        (value.is_a?(Enumerable) || value.is_a?(ActiveRecord::Associations::CollectionProxy) ? value : [value]).each do |v|
          unless v.valid?
            v.errors.full_messages.each do |msg|
              record.errors.add(attribute, msg, options.merge(:value => value))
            end
          end
        end
      end
    end

    module ClassMethods
      def validates_associated_bubbling(*attr_names)
        validates_with AssociatedBubblingValidator, _merge_attributes(attr_names)
      end
    end
  end
end

Mapotempo::Application.config.optimizer_exec = "tsp_simple"
Mapotempo::Application.config.optimizer_tmp_dir = Dir.tmpdir
Mapotempo::Application.config.optimizer_time = 20000

Mapotempo::Application.config.geocode_cache = ActiveSupport::Cache::FileStore.new(Dir.tmpdir, namespace: 'geocode', expires_in: 60*60*24*10)
Mapotempo::Application.config.geocode_reverse_cache = ActiveSupport::Cache::FileStore.new(Dir.tmpdir, namespace: 'geocode_reverse', expires_in: 60*60*24*10)
Mapotempo::Application.config.geocode_complete_cache = ActiveSupport::Cache::FileStore.new(Dir.tmpdir, namespace: 'geocode_complete', expires_in: 60*60*24*10)
Mapotempo::Application.config.geocode_ign_referer = "localhost"
Mapotempo::Application.config.geocode_ign_key = nil
Mapotempo::Application.config.geocode_complete = false # Build time setting

Mapotempo::Application.config.trace_cache_request = ActiveSupport::Cache::FileStore.new(Dir.tmpdir, namespace: 'trace_request', expires_in: 60*60*24*10)
Mapotempo::Application.config.trace_cache_result = ActiveSupport::Cache::FileStore.new(Dir.tmpdir, namespace: 'trace_result', expires_in: 60*60*24*10)
Mapotempo::Application.config.trace_osrm_url = "http://router.project-osrm.org"

Mapotempo::Application.config.delayed_job_use = false
