json.stores @planning ? @planning.routes.select(&:vehicle_usage).collect{ |route| [route.vehicle_usage.default_store_start, route.vehicle_usage.default_store_stop, route.vehicle_usage.default_store_rest] }.flatten.compact.uniq : @zoning.customer.stores do |store|
  json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
end
index = 0
json.zoning @zoning.zones do |zone|
  json.extract! zone, :id, :name, :vehicle_id, :polygon, :speed_multiplicator
  json.index index += 1
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
        json.extract! visit, :quantity1_1, :quantity1_2
        json.default_quantity1_1 1
        json.default_quantity1_2 0
        json.quantities visit_quantities(visit, route.vehicle_usage && route.vehicle_usage.vehicle) do |quantity|
          json.quantity quantity if quantity
        end
      end
      (json.duration l(visit.take_over.utc, format: :hour_minute_second)) if visit.take_over
      (json.open1 l(stop.open1.utc, format: :hour_minute)) if stop.open1
      (json.close1 l(stop.close1.utc, format: :hour_minute)) if stop.close1
      (json.open2 l(stop.open2.utc, format: :hour_minute)) if stop.open2
      (json.close2 l(stop.close2.utc, format: :hour_minute)) if stop.close2
      tags = stop.visit.tags | stop.visit.destination.tags
      color = tags.find(&:color)
      (json.color color.color) if color
      icon = tags.find(&:icon)
      (json.icon icon.icon) if icon
    end
  end
end
