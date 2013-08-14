json.extract! @planning, :id, :name
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
json.emission number_to_human(@planning.routes.to_a.sum(0){ |route| route.emission or 0 }, precision: 4)
if @planning.routes.inject(false){ |acc, route| acc or route.out_of_date }
    json.out_of_date true
end
json.size @planning.routes.to_a.sum(0){ |route| route.stops.size }
json.routes @planning.routes do |route|
  json.route_id route.id
  json.emission number_to_human(route.emission, precision: 4)
  (json.start route.start.strftime("%H:%M")) if route.start
  (json.end route.end.strftime("%H:%M")) if route.end
  (json.hidden true) if route.hidden
  (json.locked) if route.locked
  json.distance (route.distance or 0)/1000
  json.size route.stops.size
  if route.vehicle
    json.icon asset_path("marker-#{route.vehicle.color.gsub('#','')}.svg")
    json.vehicle do
      json.extract! route.vehicle, :id, :name, :color
      json.path edit_vehicle_path(route.vehicle)
    end
  end
  json.stops route.stops do |stop|
    json.extract! stop, :trace
    (json.time stop.time.strftime("%H:%M")) if stop.time
    (json.active true) if stop.active
    json.distance (stop.distance or 0)/1000
    json.destination(stop.destination, :id, :name, :street, :postalcode, :city, :lat, :lng)
    json.type (stop.destination==current_user.store)? 'store' : 'waypoint'
  end
end
