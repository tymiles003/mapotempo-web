json.zoning @zoning.zones do |zone|
  json.extract! zone, :polygon
  json.vehicles current_user.customer.vehicles do |vehicle|
    json.extract! vehicle, :id, :name
    if zone.vehicles.include? vehicle
      json.selected true
    end
  end
end
if @planning
  json.planning @planning.routes do |route|
    json.array! route.stops.collect do |stop|
      if stop.destination != current_user.customer.store
        destination = stop.destination
        json.extract! destination, :lat, :lng
        json.active route.vehicle && stop.active
      end
    end
  end
end
