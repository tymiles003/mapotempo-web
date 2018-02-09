json.route_id route.id
json.extract! route, :ref, :outdated
(json.duration (route.start && route.end) ? time_over_day(route.end - route.start) : '00:00')
(json.hidden true) if route.hidden
(json.locked true) if route.locked
json.distance locale_distance(route.distance || 0, current_user.prefered_unit)
json.size route.stops.size
json.size_active route.size_active
(json.start_time route.start_time) if route.start
(json.start_day number_of_days(route.start)) if route.start
(json.end_time route.end_time) if route.end
(json.end_day number_of_days(route.end)) if route.end

json.color_fake route.color
json.last_sent_to route.last_sent_to if route.last_sent_to
json.last_sent_at_formatted l(route.last_sent_at) if route.last_sent_at
json.optimized_at_formatted l(route.optimized_at) if route.optimized_at
unless @planning.customer.enable_orders
  json.quantities route_quantities(route) do |units|
    json.id units[:id] if units[:id]
    json.quantity units[:quantity] if units[:quantity]
    json.unit_icon units[:unit_icon]
  end
end
if route.vehicle_usage_id
  json.name (route.ref ? "#{route.ref} " : '') + route.vehicle_usage.vehicle.name
  json.color route.color || route.vehicle_usage.vehicle.color
  json.contact_email route.vehicle_usage.vehicle.contact_email if route.vehicle_usage.vehicle.contact_email
  json.vehicle_usage_id route.vehicle_usage.id
  json.devices route_devices(list_devices, route)
  json.vehicle_id route.vehicle_usage.vehicle.id
  if route.drive_time != 0 && !route.drive_time.nil?
    json.route_averages do
      json.drive_time time_over_day(route.drive_time)
      json.speed route.speed_average(current_user.prefered_unit)

      json.visits_duration time_over_day(route.visits_duration) if route.visits_duration && route.visits_duration > 0
      json.wait_time time_over_day(route.wait_time) if route.wait_time
    end
  end
  json.work_or_window_time route.vehicle_usage.work_or_window_time
  json.skills [route.vehicle_usage.tags, route.vehicle_usage.vehicle.tags].flatten.compact do |tag|
    json.icon tag.default_icon
    json.label tag.label
    json.color tag.default_color
  end

  # Devices
  route.planning.customer.device.configured_definitions.each do |key, definition|
    json.set!(key, true) if !definition[:route_operations].empty? && definition[:forms][:vehicle] && definition[:forms][:vehicle].keys.all?{ |k| !route.vehicle_usage.vehicle.devices[k].blank? }
  end
  if @with_stops
    status_uniq = route.stops.map{ |stop|
        {
          code: stop.status.downcase,
          status: t("plannings.edit.stop_status.#{stop.status.downcase}", default: stop.status)
        } if stop.status
      }.uniq.compact
    json.status_all do
      # FIXME: to avoid refreshing select active stops, combined here with hardcoded status
      json.array! status_uniq | [:planned, :started, :finished, :rejected].map{ |status|
        {
          code: status.to_s.downcase,
          status: t("plannings.edit.stop_status.#{status.to_s}")
        }
      }
    end
    json.status_any status_uniq.size > 0 || (!route.vehicle_usage.vehicle.devices[:tomtom_id].blank? && route.planning.customer.device.configured?(:tomtom))
  end
end
json.store_start do
  json.extract! route.vehicle_usage.default_store_start, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
  (json.time route.start_time) if route.start
  (json.time_day number_of_days(route.start)) if route.start
  (json.geocoded true) if route.vehicle_usage.default_store_start.position?
  (json.error true) unless route.vehicle_usage.default_store_start.position?
end if route.vehicle_usage && route.vehicle_usage.default_store_start
(json.start_with_service Time.at(display_start_time(route)).utc.strftime('%H:%M')) if display_start_time(route)
(json.start_with_service_day number_of_days(display_start_time(route))) if display_start_time(route)

json.with_stops @with_stops
if @with_stops
  inactive_stops = 0
  json.stops route.vehicle_usage_id ? route.stops.sort_by{ |s| s.index || Float::INFINITY } : (route.stops.all?{ |s| s.name.to_i != 0 } ? route.stops.sort_by{ |s| s.name.to_i } : route.stops.sort_by{ |s| s.name.to_s.downcase }) do |stop|
    (json.error true) if (stop.is_a?(StopVisit) && !stop.position?) || stop.out_of_window || stop.out_of_capacity || stop.out_of_drive_time || stop.out_of_work_time || stop.no_path
    json.stop_id stop.id
    json.stop_index stop.index
    json.extract! stop, :name, :street, :detail, :postalcode, :city, :country, :comment, :phone_number, :lat, :lng, :drive_time, :out_of_window, :out_of_capacity, :out_of_drive_time, :out_of_work_time, :no_path
    json.ref stop.ref if @planning.customer.enable_references
    json.open_close1 !!stop.open1 || !!stop.close1
    (json.open1 stop.open1_time) if stop.open1
    (json.open1_day number_of_days(stop.open1)) if stop.open1
    (json.close1 stop.close1_time) if stop.close1
    (json.close1_day number_of_days(stop.close1)) if stop.close1
    json.open_close2 !!stop.open2 || !!stop.close2
    (json.open2 stop.open2_time) if stop.open2
    (json.open2_day number_of_days(stop.open2)) if stop.open2
    (json.close2 stop.close2_time) if stop.close2
    (json.close2_day number_of_days(stop.close2)) if stop.close2
    (json.priority stop.priority) if stop.priority
    (json.wait_time '%i:%02i' % [stop.wait_time / 60 / 60, stop.wait_time / 60 % 60]) if stop.wait_time && stop.wait_time > 60
    (json.geocoded true) if stop.position?
    (json.time stop.time_time) if stop.time
    (json.time_day number_of_days(stop.time)) if stop.time
    if stop.active
      json.active true
      (json.number stop.index - inactive_stops) if route.vehicle_usage_id
    else
      inactive_stops += 1
    end
    (json.link_phone_number current_user.link_phone_number) if current_user.url_click2call
    json.distance (stop.distance || 0) / 1000
    if stop.is_a?(StopVisit)
      json.visits true
      visit = stop.visit
      json.visit_id visit.id
      json.destination do
        json.destination_id visit.destination.id
        (json.color visit.color) if visit.color
        (json.icon visit.icon) if visit.icon
      end
      json.index_visit (visit.destination.visits.index(visit) + 1) if visit.destination.visits.size > 1
      tags = visit.destination.tags | visit.tags
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
        # Hash { id, quantity, icon, label } for deliverable units
        json.quantities visit_quantities(visit, route.vehicle_usage_id && route.vehicle_usage.vehicle)
      end
      if stop.status && @planning.customer.enable_stop_status
        json.status t("plannings.edit.stop_status.#{stop.status.downcase}", default: stop.status)
        json.status_code stop.status.downcase
      end
      if stop.route.last_sent_to && stop.status && stop.eta
        (json.eta_formated l(stop.eta, format: :hour_minute)) if stop.eta
      end
    elsif stop.is_a?(StopRest)
      json.rest do
        json.rest true
        (json.store_id route.vehicle_usage.default_store_rest.id) if route.vehicle_usage.default_store_rest
        (json.geocoded true) if route.vehicle_usage.default_store_rest && route.vehicle_usage.default_store_rest.position?
        (json.error true) if route.vehicle_usage.default_store_rest && !route.vehicle_usage.default_store_rest.position?
      end
    end
    json.duration l(Time.at(stop.duration).utc, format: :hour_minute_second) if stop.duration > 0
  end
end

json.store_stop do
  json.extract! route.vehicle_usage.default_store_stop, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
  (json.time route.end_time) if route.end
  (json.time_day number_of_days(route.end)) if route.end
  (json.geocoded true) if route.vehicle_usage.default_store_stop.position?
  (json.no_path true) if route.stop_no_path
  (json.error true) if !route.vehicle_usage.default_store_stop.position? || route.stop_no_path || route.stop_out_of_drive_time || route.stop_out_of_work_time
  json.stop_out_of_drive_time route.stop_out_of_drive_time
  json.stop_out_of_work_time route.stop_out_of_work_time
  out_of_drive_time |= route.stop_out_of_drive_time
  json.stop_distance (route.stop_distance || 0) / 1000
  json.stop_drive_time route.stop_drive_time
end if route.vehicle_usage_id && route.vehicle_usage.default_store_stop
(json.end_without_service Time.at(display_end_time(route)).utc.strftime('%H:%M')) if display_end_time(route)
(json.end_without_service_day number_of_days(display_end_time(route))) if display_end_time(route)

if route.no_geolocalization || route.out_of_window || route.out_of_capacity || route.out_of_drive_time || route.out_of_work_time || route.no_path
  json.route_error true
  json.route_no_geolocalization route.no_geolocalization
  json.route_out_of_window route.out_of_window
  json.route_out_of_capacity route.out_of_capacity
  json.route_out_of_drive_time route.out_of_drive_time
  json.route_out_of_work_time route.out_of_work_time
  json.route_no_path route.no_path
end
