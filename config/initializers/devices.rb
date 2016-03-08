
Mapotempo::Application.config.devices.alyacom.api_url = 'https://alyacom.example.com'
Mapotempo::Application.config.devices.alyacom.api_key = nil
Mapotempo::Application.config.devices.masternaut.api_url = 'https://masternaut.example.com'
Mapotempo::Application.config.devices.orange.api_url = 'https://orange.example.com'
Mapotempo::Application.config.devices.tomtom.api_url = 'https://tomtom.example.com/v1.25'
Mapotempo::Application.config.devices.tomtom.api_key = nil
Mapotempo::Application.config.devices.cache_object = ActiveSupport::Cache::FileStore.new File.join(Dir.tmpdir, 'devices'), namespace: 'devices', expires_in: 30

# TomTom: Fetch WSDL when starting service
Mapotempo::Application.config.devices.tomtom.fetch_wsdl
