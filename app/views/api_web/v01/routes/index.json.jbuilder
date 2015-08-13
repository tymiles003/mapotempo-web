json.stores @routes.select{ |route| route.vehicle }.collect{ |route| [route.vehicle.store_start, route.vehicle.store_stop, route.vehicle.store_rest] }.flatten.compact.uniq do |store|
  json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng
end

json.routes @routes do |route|
  (json.out_of_date true) if route.out_of_date
  json.route_id route.id
  (json.duration '%i:%02i' % [(route.end - route.start) / 60 / 60, (route.end - route.start) / 60 % 60]) if route.start && route.end
  (json.hidden true) if route.hidden
  (json.locked true) if route.locked
  json.distance number_to_human((route.distance || 0), units: :distance, precision: 3, format: '%n %u')
  json.size route.stops.size
  json.extract! route, :ref, :size_active
  (json.quantity route.quantity) if !@planning.customer.enable_orders
  if route.vehicle
    json.vehicle_id route.vehicle.id
    json.work_time '%i:%02i' % [(route.vehicle.close - route.vehicle.open) / 60 / 60, (route.vehicle.close - route.vehicle.open) / 60 % 60]
    (json.tomtom true) if route.vehicle.tomtom_id && route.vehicle.customer.enable_tomtom && !route.vehicle.customer.tomtom_account.blank? && !route.vehicle.customer.tomtom_user.blank? && !route.vehicle.customer.tomtom_password.blank?
    (json.masternaut true) if route.vehicle.masternaut_ref && route.vehicle.customer.enable_masternaut && !route.vehicle.customer.masternaut_user.blank? && !route.vehicle.customer.masternaut_password.blank?
    (json.alyacom true) if route.vehicle.customer.enable_alyacom && !route.vehicle.customer.alyacom_association.blank?
  end
  number = 0
  no_geolocalization = out_of_window = out_of_capacity = out_of_drive_time = false
  json.store_start do
    json.extract! route.vehicle.store_start, :id, :name, :street, :postalcode, :city, :country, :lat, :lng
    (json.time route.start.strftime('%H:%M')) if route.start
  end if route.vehicle
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
    no_geolocalization |= stop.is_a?(StopDestination) && !stop.position?
    (json.error true) if (stop.is_a?(StopDestination) && !stop.position?) || stop.out_of_window || stop.out_of_capacity || stop.out_of_drive_time
    json.stop_id stop.id
    json.extract! stop, :ref, :name, :street, :detail, :postalcode, :city, :country, :comment, :lat, :lng, :trace, :out_of_window, :out_of_capacity, :out_of_drive_time
    (json.open stop.open.strftime('%H:%M')) if stop.open
    (json.close stop.close.strftime('%H:%M')) if stop.close
    (json.wait_time '%i:%02i' % [stop.wait_time / 60 / 60, stop.wait_time / 60 % 60]) if stop.wait_time && stop.wait_time > 60
    (json.geocoded true) if stop.position?
    (json.time stop.time.strftime('%H:%M')) if stop.time
    (json.active true) if stop.active
    (json.number number += 1) if route.vehicle && stop.active
    json.distance (stop.distance || 0) / 1000
    if first_active_free == true || first_active_free == stop || !route.vehicle
      json.automatic_insert true
      first_active_free = true
    end
    if stop.is_a?(StopDestination)
      json.destination do
        destination = stop.destination
        json.id destination.id
        if !destination.tags.empty?
          json.tags_present do
            json.tags do
              json.array! destination.tags do |tag|
                json.extract! tag, :label
              end
            end
          end
        end
        if @planning.customer.enable_orders
          order = stop.order
          if order
            json.orders order.products.collect(&:code).join(', ')
          end
        else
          json.extract! destination, :quantity
        end
        (json.duration destination.take_over.strftime('%H:%M:%S')) if destination.take_over
        color = destination.tags.find(&:color)
        (json.color color.color) if color
        icon = destination.tags.find(&:icon)
        (json.icon icon.icon) if icon
      end
    elsif stop.is_a?(StopRest)
      json.rest do
        (json.duration route.vehicle.rest_duration.strftime('%H:%M:%S')) if route.vehicle.rest_duration
        (json.store_id route.vehicle.store_rest.id) if route.vehicle.store_rest
      end
    end
  end
  json.store_stop do
    json.extract! route.vehicle.store_stop, :id, :name, :street, :postalcode, :city, :country, :lat, :lng
    (json.time route.end.strftime('%H:%M')) if route.end
    json.stop_trace route.stop_trace
    (json.error true) if route.stop_out_of_drive_time
    json.stop_out_of_drive_time route.stop_out_of_drive_time
    json.stop_distance (route.stop_distance || 0) / 1000
  end if route.vehicle
  (json.route_no_geolocalization no_geolocalization) if no_geolocalization
  (json.route_out_of_window out_of_window) if out_of_window
  (json.route_out_of_capacity out_of_capacity) if out_of_capacity
  (json.route_out_of_drive_time out_of_drive_time) if out_of_drive_time
  (json.route_error true) if no_geolocalization || out_of_window || out_of_capacity || out_of_drive_time
end
