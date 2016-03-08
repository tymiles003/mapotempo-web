
require_relative '../../lib/device_base'
['alyacom', 'masternaut', 'orange', 'teksat', 'tomtom'].each{|name|
  require_relative "../../lib/devices/#{name}"
}

Mapotempo::Application.config.devices = OpenStruct.new alyacom: Alyacom.new, masternaut: Masternaut.new, orange: Orange.new, teksat: Teksat.new, tomtom: Tomtom.new
Mapotempo::Application.config.devices.cache_object = ActiveSupport::Cache::FileStore.new File.join(Dir.tmpdir, 'devices'), namespace: 'devices', expires_in: 30

# API URL / Keys
Mapotempo::Application.config.devices.alyacom.api_url = 'https://alyacom.example.com'
Mapotempo::Application.config.devices.masternaut.api_url = 'https://masternaut.example.com'
Mapotempo::Application.config.devices.orange.api_url = 'https://orange.example.com'
Mapotempo::Application.config.devices.tomtom.api_url = 'https://tomtom.example.com/v1.26'
