json.stores @planning ? @planning.routes.select(&:vehicle_usage).collect{ |route| [route.vehicle_usage.default_store_start, route.vehicle_usage.default_store_stop, route.vehicle_usage.default_store_rest] }.flatten.compact.uniq : @zoning.customer.stores do |store|
  json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
end
json.zoning @zoning.zones do |zone|
  json.extract! zone, :id, :vehicle_id, :polygon
end
if @planning
  json.planning @planning.routes do |route|
    if route.vehicle_usage
      json.vehicle_id route.vehicle_usage.vehicle.id
    end
    json.stops route.stops.select{ |stop| stop.is_a?(StopVisit) }.collect do |stop|
      visit = stop.visit
      json.extract! visit, :id
      json.extract! visit.destination, :id, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :phone_number, :comment
      json.ref visit.ref if @zoning.customer.enable_references
      json.active route.vehicle_usage && stop.active
      if !@planning.customer.enable_orders
        json.extract! visit, :quantity
      end
      (json.duration l(visit.take_over, format: :hour_minute_second)) if visit.take_over
      (json.open l(stop.open, format: :hour_minute)) if stop.open
      (json.close l(stop.close, format: :hour_minute)) if stop.close
      tags = stop.visit.tags | stop.visit.destination.tags
      color = tags.find(&:color)
      (json.color color.color) if color
      icon = tags.find(&:icon)
      (json.icon icon.icon) if icon
    end
  end
end
