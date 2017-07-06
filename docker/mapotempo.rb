Rails.application.configure do
  config.optimize.url = 'http://localhost:8083/0.1'
  config.optimize.api_key = 'demo'
  config.geocode_geocoder.url = 'http://localhost:8081/0.1'
  config.geocode_geocoder.api_key = 'demo'
  # The Router API URL is in the application database.
  config.router_wrapper.api_key = 'demo'
end
