json.stores @planning ? (@planning.routes.select(&:vehicle_usage).collect(&:vehicle_usage).collect(&:default_store_start) + @planning.routes.select(&:vehicle_usage).collect(&:vehicle_usage).collect(&:default_store_stop)).uniq : @zoning.customer.stores do |store|
  json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng
end
json.zoning @zoning.zones do |zone|
  json.extract! zone, :id, :vehicle_id, :polygon
end
if @planning
  json.planning @planning.routes do |route|
    if route.vehicle_usage
      json.vehicle_id route.vehicle_usage.vehicle.id
    end
    json.stops do
      json.array! route.stops.select{ |stop| stop.is_a?(StopDestination) }.collect do |stop|
        destination = stop.destination
        json.extract! destination, :id, :ref, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :phone_number, :comment
        json.active route.vehicle_usage && stop.active
        if !@planning.customer.enable_orders
          json.extract! destination, :quantity
        end
        (json.duration destination.take_over.strftime('%H:%M:%S')) if destination.take_over
        (json.open stop.open.strftime('%H:%M')) if stop.open
        (json.close stop.close.strftime('%H:%M')) if stop.close
        color = stop.destination.tags.find(&:color)
        (json.color color.color) if color
        icon = stop.destination.tags.find(&:icon)
        (json.icon icon.icon) if icon
      end
    end
  end
end
