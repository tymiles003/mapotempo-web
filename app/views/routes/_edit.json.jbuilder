json.route_id route.id
(json.duration (route.start && route.end) ? '%i:%02i' % [(route.end - route.start) / 60 / 60, (route.end - route.start) / 60 % 60] : '0:00')
(json.hidden true) if route.hidden
(json.locked true) if route.locked
json.distance number_to_human((route.distance || 0), units: :distance, precision: 3, format: '%n %u')
json.size route.stops.size
json.extract! route, :ref, :color, :size_active
json.color_fake route.color
(json.quantity route.quantity) if !@planning.customer.enable_orders
if route.vehicle_usage
  json.contact_email route.vehicle_usage.vehicle.contact_email if route.vehicle_usage.vehicle.contact_email
  json.capacity_unit route.vehicle_usage.vehicle.capacity_unit
  json.vehicle_usage_id route.vehicle_usage.id
  json.vehicle_id route.vehicle_usage.vehicle.id
  json.work_time '%i:%02i' % [(route.vehicle_usage.default_close - route.vehicle_usage.default_open) / 60 / 60, (route.vehicle_usage.default_close - route.vehicle_usage.default_open) / 60 % 60]
  (json.tomtom true) if route.vehicle_usage.vehicle.tomtom_id && route.planning.customer.tomtom?
  (json.masternaut true) if route.vehicle_usage.vehicle.masternaut_ref && route.planning.customer.enable_masternaut && !route.planning.customer.masternaut_user.blank? && !route.planning.customer.masternaut_password.blank?
  (json.alyacom true) if route.planning.customer.enable_alyacom && !route.planning.customer.alyacom_association.blank?
end
number = 0
no_geolocalization = out_of_window = out_of_capacity = out_of_drive_time = no_path = false
json.store_start do
  json.extract! route.vehicle_usage.default_store_start, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
  (json.time l(route.start, format: :hour_minute)) if route.start
  (json.with_service_time l(display_start_time(route), format: :hour_minute)) if display_start_time(route)
  (json.geocoded true) if !route.vehicle_usage.default_store_start.lat.nil? && !route.vehicle_usage.default_store_start.lng.nil?
  (json.error true) if route.vehicle_usage.default_store_start.lat.nil? || route.vehicle_usage.default_store_start.lng.nil?
end if route.vehicle_usage && route.vehicle_usage.default_store_start
first_active_free = nil
route.stops.reverse_each{ |stop|
  if !stop.active
    first_active_free = stop
  else
    break
  end
}
json.stops route.stops.sort_by{ |s| s.index || Float::INFINITY } do |stop|
  duration = nil
  out_of_window |= stop.out_of_window
  out_of_capacity |= stop.out_of_capacity
  out_of_drive_time |= stop.out_of_drive_time
  no_geolocalization |= stop.is_a?(StopVisit) && !stop.position?
  no_path |= stop.position? && route.vehicle_usage && !stop.trace && stop.active
  (json.error true) if (stop.is_a?(StopVisit) && !stop.position?) || (stop.position? && route.vehicle_usage && !stop.trace && stop.active) || stop.out_of_window || stop.out_of_capacity || stop.out_of_drive_time
  json.edit_planning true
  json.stop_id stop.id
  json.extract! stop, :name, :street, :detail, :postalcode, :city, :country, :comment, :phone_number, :lat, :lng, :drive_time, :trace, :out_of_window, :out_of_capacity, :out_of_drive_time
  json.ref stop.ref if @planning.customer.enable_references
  json.open_close stop.open || stop.close
  (json.open l(stop.open, format: :hour_minute)) if stop.open
  (json.close l(stop.close, format: :hour_minute)) if stop.close
  (json.wait_time '%i:%02i' % [stop.wait_time / 60 / 60, stop.wait_time / 60 % 60]) if stop.wait_time && stop.wait_time > 60
  (json.geocoded true) if stop.position?
  (json.no_path true) if stop.position? && route.vehicle_usage && !stop.trace && stop.active
  (json.time l(stop.time, format: :hour_minute)) if stop.time
  (json.active true) if stop.active
  (json.number number += 1) if route.vehicle_usage && stop.active
  (json.link_phone_number current_user.link_phone_number) if current_user.url_click2call
  json.distance (stop.distance || 0) / 1000
  if first_active_free == true || first_active_free == stop || !route.vehicle_usage
    json.automatic_insert true
    first_active_free = true
  end
  if stop.is_a?(StopVisit)
    json.visits true
    visit = stop.visit
    json.visit_id visit.id
    tags = visit.destination.tags | visit.tags
    json.destination do
      json.destination_id visit.destination.id
      color = tags.find(&:color)
      (json.color color.color) if color
      icon = tags.find(&:icon)
      (json.icon icon.icon) if icon
    end
    json.index_visit (visit.destination.visits.index(visit) + 1) if visit.destination.visits.size > 1
    if !tags.empty?
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
      json.extract! visit, :quantity
    end
    duration = l(visit.take_over, format: :hour_minute_second) if visit.take_over
  elsif stop.is_a?(StopRest)
    json.rest do
      json.rest true
      duration = l(route.vehicle_usage.default_rest_duration, format: :hour_minute_second) if route.vehicle_usage.default_rest_duration
      (json.store_id route.vehicle_usage.default_store_rest.id) if route.vehicle_usage.default_store_rest
      (json.geocoded true) if !route.vehicle_usage.default_store_rest.nil? && !route.vehicle_usage.default_store_rest.lat.nil? && !route.vehicle_usage.default_store_rest.lng.nil?
      (json.error true) if !route.vehicle_usage.default_store_rest.nil? && (route.vehicle_usage.default_store_rest.lat.nil? || route.vehicle_usage.default_store_rest.lng.nil?)
    end
  end
  json.duration duration if duration
end
json.store_stop do
  json.extract! route.vehicle_usage.default_store_stop, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
  (json.time l(route.end, format: :hour_minute)) if route.end
  (json.with_service_time l(display_end_time(route), format: :hour_minute)) if display_end_time(route)
  (json.geocoded true) if !route.vehicle_usage.default_store_stop.lat.nil? && !route.vehicle_usage.default_store_stop.lng.nil?
  (json.no_path true) if route.distance > 0 && !route.vehicle_usage.default_store_stop.lat.nil? && !route.vehicle_usage.default_store_stop.lng.nil? && !route.stop_trace
  (json.error true) if (route.vehicle_usage.default_store_stop.lat.nil? || route.vehicle_usage.default_store_stop.lng.nil?) || (route.distance > 0 && !route.vehicle_usage.default_store_stop.lat.nil? && !route.vehicle_usage.default_store_stop.lng.nil? && !route.stop_trace)
  json.stop_trace route.stop_trace
  (json.error true) if route.stop_out_of_drive_time
  json.stop_out_of_drive_time route.stop_out_of_drive_time
  out_of_drive_time |= route.stop_out_of_drive_time
  json.stop_distance (route.stop_distance || 0) / 1000
  json.stop_drive_time route.stop_drive_time
end if route.vehicle_usage && route.vehicle_usage.default_store_stop
(json.route_no_geolocalization no_geolocalization) if no_geolocalization
(json.route_out_of_window out_of_window) if out_of_window
(json.route_out_of_capacity out_of_capacity) if out_of_capacity
(json.route_out_of_drive_time out_of_drive_time) if out_of_drive_time
(json.route_no_path no_path) if no_path
(json.route_error true) if no_geolocalization || out_of_window || out_of_capacity || out_of_drive_time
