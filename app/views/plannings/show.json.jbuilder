json.extract! @planning, :name
json.tags do
  json.array!(@planning.tags) do |tag|
    json.extract! tag, :label
  end
end
json.vehicles do
  json.array!(current_user.vehicles) do |vehicle|
    json.extract! vehicle, :id, :name
  end
end
json.distance @planning.routes.to_a.sum(0){ |route| route.distance or 0 }/1000
json.emission @planning.routes.to_a.sum(0){ |route| route.emission or 0 }
if @planning.routes.inject(false){ |acc, route| acc or route.out_of_date }
    json.out_of_date true
end
json.routes @planning.routes do |route|
  json.extract! route, :id, :emission
  json.distance (route.distance or 0)/1000
  if route.vehicle
    json.icon asset_path("marker-#{route.vehicle.color.gsub('#','')}.svg")
    json.vehicle do
      json.extract! route.vehicle, :id, :name, :color
      json.path edit_vehicle_path(route.vehicle)
    end
  end
  json.stops route.stops do |stop|
    json.extract! stop, :trace
    if stop.active
      json.active true
    end
    json.distance (stop.distance or 0)/1000
    json.destination(stop.destination, :id, :name, :street, :postalcode, :city, :lat, :lng)
  end
end
