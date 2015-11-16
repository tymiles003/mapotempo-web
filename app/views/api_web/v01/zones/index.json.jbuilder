json.stores @planning ? (@planning.routes.select(&:vehicle_usage).collect(&:vehicle_usage).collect(&:default_store_start) + @planning.routes.select(&:vehicle_usage).collect(&:vehicle_usage).collect(&:default_store_stop)).uniq : @zoning.customer.stores do |store|
  json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng
end
json.zoning @zones do |zone|
  json.extract! zone, :id, :vehicle_id, :polygon
end
if @destinations
  json.destinations do
    json.array! @destinations, partial: 'api_web/v01/destinations/show', as: :destination
  end
end
