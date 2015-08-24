json.customers @customers do |customer|
  json.extract! customer, :id, :name, :test, :max_vehicles
  json.lat customer.stores[0].lat
  json.lng customer.stores[0].lng
end
