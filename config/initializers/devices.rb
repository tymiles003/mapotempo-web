
class DeviceServiceError < StandardError ; end

require_relative '../../lib/devices/device_base'
['alyacom', 'masternaut', 'orange', 'teksat', 'tomtom'].each{|name|
  require_relative "../../lib/devices/#{name}"
}

Mapotempo::Application.config.devices = OpenStruct.new alyacom: Alyacom.new, masternaut: Masternaut.new, orange: Orange.new, teksat: Teksat.new, tomtom: Tomtom.new
Mapotempo::Application.config.devices.cache_object = ActiveSupport::Cache::FileStore.new File.join(Dir.tmpdir, 'devices'), namespace: 'devices', expires_in: 30

# API URL / Keys
if Rails.env.test?
  Mapotempo::Application.config.devices.alyacom.api_url = 'https://alyacom.example.com'
  Mapotempo::Application.config.devices.masternaut.api_url = 'https://masternaut.example.com'
  Mapotempo::Application.config.devices.orange.api_url = 'https://orange.example.com'
  Mapotempo::Application.config.devices.tomtom.api_url = 'https://tomtom.example.com/v1.26'
elsif Rails.env.development?
  Mapotempo::Application.config.devices.alyacom.api_url = 'http://partners.alyacom.fr/ws'
  Mapotempo::Application.config.devices.masternaut.api_url = 'http://ws.webservices.masternaut.fr/MasterWS/services'
  Mapotempo::Application.config.devices.orange.api_url = 'https://m2m-services.ft-dm.com'
  Mapotempo::Application.config.devices.tomtom.api_url = 'https://soap.business.tomtom.com/v1.26'
end
