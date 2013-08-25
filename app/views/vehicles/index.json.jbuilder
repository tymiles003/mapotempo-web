json.array!(@vehicles) do |vehicle|
  json.extract! vehicle, :name, :emission, :consumption, :capacity, :color, :open, :close, :customer_id
  json.url vehicle_url(vehicle, format: :json)
end
