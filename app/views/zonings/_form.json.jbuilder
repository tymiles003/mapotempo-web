json.zoning @zoning.zones do |zone|
  json.extract! zone, :id, :vehicle_id, :polygon
end
if @planning
  json.planning @planning.routes do |route|
    if route.vehicle
      json.vehicle_id route.vehicle.id
    end
    json.stops do
      json.array! route.stops.collect do |stop|
        json.extract! stop.destination, :lat, :lng
        json.active route.vehicle && stop.active
      end
    end
  end
end
