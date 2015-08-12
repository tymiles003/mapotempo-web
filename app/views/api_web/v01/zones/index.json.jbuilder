json.stores @zones.select{ |zone| zone.vehicle }.collect{ |zone| [zone.vehicle.store_start, zone.vehicle.store_stop, zone.vehicle.store_rest] }.flatten.compact.uniq do |store|
  json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng
end
json.zoning @zones do |zone|
  json.extract! zone, :id, :vehicle_id, :polygon
end
