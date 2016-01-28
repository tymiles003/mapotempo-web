if @vehicle_usage_set
  vehicle_vehicle_usages = Hash[@vehicle_usage_set.vehicle_usages.collect{ |vehicle_usage| [vehicle_usage.vehicle, vehicle_usage] }]
  vehicle_usages = @zones.select(&:vehicle).collect{ |zone| vehicle_vehicle_usages[zone.vehicle] }
end
if @stores
  stores = @stores
elsif vehicle_usages
  stores = (vehicle_usages.collect(&:default_store_start) + vehicle_usages.collect(&:default_store_stop) + vehicle_usages.collect(&:default_store_rest)).compact.uniq
else
  stores = @zoning.customer.stores
end
json.stores stores do |store|
  json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
end
json.zoning @zones do |zone|
  json.extract! zone, :id, :vehicle_id, :polygon
end
if @destinations
  json.destinations @destinations, partial: 'api_web/v01/destinations/show', as: :destination
end
