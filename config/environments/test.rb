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
  config.action_view.raise_on_missing_translations = true

  # Application config

  config.action_mailer.default_url_options = {host: 'localhost'}

  config.default_from_mail = 'root@localhost'

  config.swagger_docs_base_path = 'http://localhost:3000/'

  def cache_factory(namespace, expires_in)
    ActiveSupport::Cache::NullStore.new
  end

  # config.optimize = Ort.new(
  #   cache_factory('optimizer', 60*60*24*10),
  #   'http://localhost:4567/0.1/optimize_tsptw'
  # )
  config.optimize = OptimizerWrapper.new(
    cache_factory('optimizer_wrapper', 60*60*24*10),
    'http://optim.mapotempo.com:1791/0.1',
    'api_key'
  )
  config.optimize_time = nil
  config.optimize_time_force = 1
  config.optimize_cluster_size = 0
  config.optimize_stop_soft_upper_bound = 0.3
  config.optimize_vehicle_soft_upper_bound = 0.3

  config.geocode_code_cache = cache_factory('geocode', 60*60*24*10)
  config.geocode_reverse_cache = cache_factory('geocode_reverse', 60*60*24*10)
  config.geocode_complete_cache = cache_factory('geocode_complete', 60*60*24*10)
  config.geocode_complete = true # Build time setting

  require 'geocode_addok_wrapper'
  config.geocode_geocoder = GeocodeAddokWrapper.new('https://geocode.mapotempo.com/0.1', 'demo')

  config.router_osrm = Routers::Osrm.new(
    cache_factory('osrm_request', 60*60*24*1),
    cache_factory('osrm_result', 60*60*24*1)
  )
  config.router_otp = Routers::Otp.new(
    cache_factory('otp_request', 60*60*24*1),
    cache_factory('otp_result', 60*60*24*1)
  )
  config.router_here = Routers::Here.new(
    cache_factory('here_request', 60*60*24*1),
    cache_factory('here_result', 60*60*24*1),
    'https://route.api.here.com/routing',
    'https://matrix.route.api.here.com/routing',
    'https://isoline.route.api.here.com/routing',
    'app_id',
    'app_code'
  )
  config.router_wrapper = Routers::RouterWrapper.new(
    cache_factory('router_wrapper_request', 60*60*24*1),
    cache_factory('router_wrapper_result', 60*60*24*1),
    'api_key'
  )

  config.devices.alyacom.api_url = 'https://alyacom.example.com'
  config.devices.masternaut.api_url = 'https://masternaut.example.com'
  config.devices.orange.api_url = 'https://orange.example.com'
  config.devices.tomtom.api_url = 'https://tomtom.example.com' #v1.26
  config.devices.tomtom.api_key = nil
  config.devices.cache_object = cache_factory('devices', 30)

  config.delayed_job_use = false

  config.self_care = true # Allow subscription and resiliation by the user himself

  config.max_destinations = 3000
  config.max_destinations_editable = 1000
  config.manage_vehicles_only_admin = false

  config.enable_references = true
  config.enable_multi_visits = false
end

I18n.available_locales = [:fr]
I18n.enforce_available_locales = false
I18n.default_locale = :fr
