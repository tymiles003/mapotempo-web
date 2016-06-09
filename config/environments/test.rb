Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static file server for tests with Cache-Control for performance.
  config.serve_static_files   = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Application config

  config.optimize = Ort.new(
    ActiveSupport::Cache::NullStore.new,
    'http://localhost:4567/0.1/optimize_tsptw'
  )
  config.geocode_code_cache = ActiveSupport::Cache::NullStore.new
  config.geocode_reverse_cache = ActiveSupport::Cache::NullStore.new
  config.geocode_complete_cache = ActiveSupport::Cache::NullStore.new

  config.router_osrm = Routers::Osrm.new(
    ActiveSupport::Cache::NullStore.new,
    ActiveSupport::Cache::NullStore.new
  )
  config.router_otp = Routers::Otp.new(
    ActiveSupport::Cache::NullStore.new,
    ActiveSupport::Cache::NullStore.new
  )
  config.router_here = Routers::Here.new(
    ActiveSupport::Cache::NullStore.new,
    ActiveSupport::Cache::NullStore.new,
    'https://route.api.here.com/routing',
    'https://matrix.route.api.here.com/routing',
    'https://isoline.route.api.here.com/routing',
    nil, nil
  )
  config.router_wrapper = Routers::RouterWrapper.new(
    ActiveSupport::Cache::NullStore.new,
    ActiveSupport::Cache::NullStore.new,
    nil
  )

  config.devices.cache_object = ActiveSupport::Cache::NullStore.new

  config.devices.alyacom.api_url = 'https://alyacom.example.com'
  config.devices.masternaut.api_url = 'https://masternaut.example.com'
  config.devices.orange.api_url = 'https://orange.example.com'
  config.devices.tomtom.api_url = 'https://tomtom.example.com' #v1.26

  config.delayed_job_use = false
  config.geocode_complete = true

  config.router_wrapper.api_key = 'api_key'
end

I18n.available_locales = [:fr]
I18n.enforce_available_locales = false
I18n.default_locale = :fr
