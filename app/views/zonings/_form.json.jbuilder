json.stores @planning ? (@planning.routes.select(&:vehicle).collect(&:vehicle).collect(&:store_start) + @planning.routes.select(&:vehicle).collect(&:vehicle).collect(&:store_stop)).uniq : @zoning.customer.stores do |store|
  json.extract! store, :id, :name, :street, :postalcode, :city, :lat, :lng
end
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
        color = stop.destination.tags.find{ |tag| tag.color }
        (json.color color.color) if color
        icon = stop.destination.tags.find{ |tag| tag.icon }
        (json.icon icon.icon) if icon
      end
    end
  end
end
