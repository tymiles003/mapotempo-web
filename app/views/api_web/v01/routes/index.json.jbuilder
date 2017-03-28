json.planning_id @planning.id

json.stores @routes.select{ |route| route.vehicle_usage }.collect{ |route| [route.vehicle_usage.default_store_start, route.vehicle_usage.default_store_stop, route.vehicle_usage.default_store_rest] }.flatten.compact.uniq do |store|
  json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
end

json.routes @routes do |route|
  (json.out_of_date true) if route.out_of_date
  json.route_id route.id
  (json.duration '%i:%02i' % [(route.end - route.start) / 60 / 60, (route.end - route.start) / 60 % 60]) if route.start && route.end
  (json.hidden true) if route.hidden
  (json.locked true) if route.locked
  json.distance number_to_human((route.distance || 0), units: :distance, precision: 3, format: '%n %u')
  json.size route.stops.size
  json.extract! route, :color, :size_active
  json.ref route.ref if @planning.customer.enable_references
  unless @planning.customer.enable_orders
    json.quantities route.quantities
  end
  if route.vehicle_usage
    json.vehicle_id route.vehicle_usage.vehicle.id
    json.work_time '%i:%02i' % [(route.vehicle_usage.default_close - route.vehicle_usage.default_open) / 60 / 60, (route.vehicle_usage.default_close - route.vehicle_usage.default_open) / 60 % 60]
  end
  number = 0
  no_geolocalization = out_of_window = out_of_capacity = out_of_drive_time = no_path = false
  json.store_start do
    json.extract! route.vehicle_usage.default_store_start, :id, :name, :street, :postalcode, :city, :country, :lat, :lng
    (json.time route.start_time) if route.start
    (json.time_day number_of_days(route.start)) if route.start
  end if route.vehicle_usage && route.vehicle_usage.default_store_start
  previous_with_pos = route.vehicle_usage && route.vehicle_usage.default_store_start.try(&:position?)
  first_active_free = nil
  route.stops.reverse_each{ |stop|
    if !stop.active
      first_active_free = stop
    else
      break
    end
  }
  json.stops route.stops do |stop|
    out_of_window |= stop.out_of_window
    out_of_capacity |= stop.out_of_capacity
    out_of_drive_time |= stop.out_of_drive_time
    no_geolocalization |= stop.is_a?(StopVisit) && !stop.position?
    no_path |= stop.position? && stop.active && route.vehicle_usage && !stop.trace && previous_with_pos
    (json.error true) if (stop.is_a?(StopVisit) && !stop.position?) || (stop.position? && stop.active && route.vehicle_usage && !stop.trace && previous_with_pos) || stop.out_of_window || stop.out_of_capacity || stop.out_of_drive_time
    json.stop_id stop.id
    json.extract! stop, :name, :street, :detail, :postalcode, :city, :country, :comment, :phone_number, :lat, :lng, :drive_time, :trace, :out_of_window, :out_of_capacity, :out_of_drive_time
    json.ref stop.ref if @planning.customer.enable_references
    json.open_close1 stop.open1 || stop.close1
    json.open1 stop.open1_time
    json.close1 stop.close1_time
    json.open1_close1_days number_of_days(stop.close1)
    json.open_close2 stop.open2 || stop.close2
    json.open2 stop.open2_time
    json.close2 stop.close2_time
    json.open2_close2_days number_of_days(stop.close2)
    (json.wait_time '%i:%02i' % [stop.wait_time / 60 / 60, stop.wait_time / 60 % 60]) if stop.wait_time && stop.wait_time > 60
    (json.geocoded true) if stop.position?
    (json.no_path true) if stop.position? && stop.active && route.vehicle_usage && !stop.trace && previous_with_pos
    (json.time stop.time_time) if stop.time
    (json.time_day number_of_days(stop.time)) if stop.time
    (json.active true) if stop.active
    (json.number number += 1) if route.vehicle_usage && stop.active
    json.distance (stop.distance || 0) / 1000
    if first_active_free == true || first_active_free == stop || !route.vehicle_usage
      json.automatic_insert true
      first_active_free = true
    end
    if stop.is_a?(StopVisit)
      json.visits true
      visit = stop.visit
      json.visit_id visit.id
      json.destination do
        json.destination_id visit.destination.id
        (json.color visit.color) if visit.color
        (json.icon visit.icon) if visit.icon
      end
      tags = visit.destination.tags | visit.tags
      unless tags.empty?
        json.tags_present do
          json.tags do
            json.array! tags, :label
          end
        end
      end
      if @planning.customer.enable_orders
        order = stop.order
        if order
          json.orders order.products.collect(&:code).join(', ')
        end
      else
        json.quantities visit_quantities(visit, route.vehicle_usage && route.vehicle_usage.vehicle) do |units|
          json.quantity units[:quantity] if units[:quantity]
          json.unit_icon units[:unit_icon]
        end
      end
    elsif stop.is_a?(StopRest)
      json.rest do
        (json.store_id route.vehicle_usage.default_store_rest.id) if route.vehicle_usage.default_store_rest
      end
    end
    json.duration stop.duration_time_in_seconds if stop.duration > 0
    previous_with_pos = stop if stop.position?
  end
  json.store_stop do
    json.extract! route.vehicle_usage.default_store_stop, :id, :name, :street, :postalcode, :city, :country, :lat, :lng
    (json.time route.end_time) if route.end
    (json.time_day number_of_days(route.end)) if route.end
    json.stop_trace route.stop_trace
    json.stop_distance (route.stop_distance || 0) / 1000
    json.stop_drive_time route.stop_drive_time
    (json.error true) if route.stop_out_of_drive_time || (route.distance > 0 && route.vehicle_usage.default_store_stop.position? && !route.stop_trace)
    json.stop_out_of_drive_time route.stop_out_of_drive_time
    out_of_drive_time |= route.stop_out_of_drive_time
    (json.no_path true) if route.distance > 0 && route.vehicle_usage.default_store_stop.position? && !route.stop_trace
  end if route.vehicle_usage && route.vehicle_usage.default_store_stop
  (json.route_no_geolocalization no_geolocalization) if no_geolocalization
  (json.route_out_of_window out_of_window) if out_of_window
  (json.route_out_of_capacity out_of_capacity) if out_of_capacity
  (json.route_out_of_drive_time out_of_drive_time) if out_of_drive_time
  (json.route_no_path no_path) if no_path
  (json.route_error true) if no_geolocalization || out_of_window || out_of_capacity || out_of_drive_time
end
