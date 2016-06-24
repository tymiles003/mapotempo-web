require File.expand_path('../boot', __FILE__)

require 'rails/all'
require_relative '../app/middleware/reseller_by_host'
require_relative '../lib/routers/osrm'
require_relative '../lib/routers/otp'
require_relative '../lib/routers/here'
require_relative '../lib/routers/router_wrapper'
require_relative '../lib/optim/ort'
require_relative '../lib/optim/optimizer_wrapper'

require_relative '../lib/devices/device_base'
['alyacom', 'masternaut', 'orange', 'teksat', 'tomtom'].each{|name|
  require_relative "../lib/devices/#{name}"
}

# Fixes OpenStruct + Ruby 1.9, for devices
unless OpenStruct.new.respond_to? :[]
  OpenStruct.class_eval do
    extend Forwardable
    def_delegators :@table, :[], :[]=
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'devise'

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

    I18n.available_locales = %w(en fr)

    config.autoload_paths += %W(#{config.root}/app/services #{config.root}/app/api/v01/helper)

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Application config

    config.assets.initialize_on_precompile = true

    config.middleware.use Rack::Config do |env|
      env['api.tilt.root'] = Rails.root.join 'app', 'api', 'views'
    end

    config.middleware.insert_before 0, 'Rack::Cors' do
      allow do
        origins '*'
        resource '/api-web/0.1/*', headers: :any, methods: [:get, :post, :options, :put, :delete, :patch]
        resource '/api/0.1/*', headers: :any, methods: [:get, :post, :options, :put, :delete, :patch]
      end
    end

    config.middleware.use ::ResellerByHost

    config.lograge.enabled = true
    config.lograge.custom_options = lambda do |event|
      unwanted_keys = %w[format action controller]
      customer_id = event.payload[:customer_id]
      params = event.payload[:params].reject { |key,_| unwanted_keys.include? key }

      {customer_id: customer_id, time: event.time, params: params}
    end

    config.devices = OpenStruct.new alyacom: Alyacom.new, masternaut: Masternaut.new, orange: Orange.new, teksat: Teksat.new, tomtom: Tomtom.new
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

class TwitterBootstrapFormFor::FormBuilder
  def submit(value=nil, options={}, icon=false)
    value, options = nil, value if value.is_a?(Hash)
    options[:class] ||= 'btn btn-primary'
    value ||= submit_default_value
    @template.button_tag(options) {
      if icon != nil
        icon ||= 'fa-floppy-o'
        @template.concat @template.content_tag('i', nil, class: "fa #{icon} fa-fw")
      end
      @template.concat ' '
      @template.concat value
    }
  end
end
