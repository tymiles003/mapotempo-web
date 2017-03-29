json.stores @planning ? @planning.routes.select(&:vehicle_usage).collect { |route| [route.vehicle_usage.default_store_start, route.vehicle_usage.default_store_stop, route.vehicle_usage.default_store_rest] }.flatten.compact.uniq : @zoning.customer.stores do |store|
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
    json.stops route.stops.select { |stop| stop.is_a?(StopVisit) }.collect do |stop|
      visit = stop.visit
      json.extract! visit, :id
      json.extract! visit.destination, :id, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :phone_number, :comment
      json.ref visit.ref if @zoning.customer.enable_references
      json.active route.vehicle_usage && stop.active
      unless @planning.customer.enable_orders
        json.quantities visit.default_quantities.map { |k, v|
          {deliverable_unit_id: k, quantity: v, unit_icon: @planning.customer.deliverable_units.find { |du| du.id == k }.try(:default_icon)} unless v.nil?
        }.compact do |quantity|
          json.extract! quantity, :deliverable_unit_id, :quantity, :unit_icon
        end
      end
      (json.duration visit.default_take_over_time_with_seconds) if visit.default_take_over_time_with_seconds
      (json.open1 stop.open1_time) if stop.open1
      (json.close1 stop.close1_time) if stop.close1
      (json.open2 stop.open2_time) if stop.open2
      (json.close2 stop.close2_time) if stop.close2
      (json.color visit.color) if visit.color
      (json.icon visit.icon) if visit.icon
    end
  end
end
