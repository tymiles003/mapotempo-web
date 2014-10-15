if current_user.customer.job_matrix
  json.matrix do
    json.extract! current_user.customer.job_matrix, :progress, :attempts
    json.error !!current_user.customer.job_matrix.failed_at
  end
elsif current_user.customer.job_optimizer
  json.optimizer do
    json.extract! current_user.customer.job_optimizer, :progress, :attempts
    json.error !!current_user.customer.job_optimizer.failed_at
  end
else
  json.extract! @planning, :id
  json.distance number_to_human(@planning.routes.to_a.sum(0){ |route| route.distance or 0 }, units: :distance, precision: 3, format: '%n %u')
  json.emission number_to_human(@planning.routes.to_a.sum(0){ |route| route.emission or 0 }, precision: 4)
  (json.out_of_date true) if @planning.out_of_date
  (json.zoning_out_of_date true) if @planning.zoning_out_of_date
  json.size @planning.routes.to_a.sum(0){ |route| route.stops.size }
  json.size_active @planning.routes.to_a.sum(0){ |route| route.vehicle ? route.size_active : 0 }
  json.stores current_user.customer.stores do |store|
    json.extract! store, :id, :lat, :lng
  end
  json.routes @planning.routes do |route|
    json.route_id route.id
    (json.duration "%i:%02i" % [(route.end - route.start)/60/60, (route.end - route.start)/60%60]) if route.start && route.end
    (json.hidden true) if route.hidden
    (json.locked) if route.locked
    json.distance number_to_human((route.distance or 0), units: :distance, precision: 3, format: '%n %u')
    json.size route.stops.size
    json.size_active route.size_active
    json.quantity route.quantity
    if route.vehicle
      json.vehicle_id route.vehicle.id
      json.work_time "%i:%02i" % [(route.vehicle.close - route.vehicle.open)/60/60, (route.vehicle.close - route.vehicle.open)/60%60]
      (json.tomtom true) if route.vehicle.tomtom_id && !route.vehicle.customer.tomtom_account.blank? && !route.vehicle.customer.tomtom_user.blank? && !route.vehicle.customer.tomtom_password.blank?
    end
    number = 0
    no_geocoding = out_of_window = out_of_capacity = out_of_drive_time = false
    json.store_start do
      json.extract! route.vehicle.store_start, :id, :name, :street, :postalcode, :city, :lat, :lng
      (json.time route.start.strftime("%H:%M")) if route.start
    end if route.vehicle
    json.stops route.stops do |stop|
      out_of_window |= stop.out_of_window
      out_of_capacity |= stop.out_of_capacity
      out_of_drive_time |= stop.out_of_drive_time
      no_geocoding |= stop.destination.lat == nil || stop.destination.lng == nil
      (json.error true) if stop.destination.lat == nil || stop.destination.lng == nil || stop.out_of_window || stop.out_of_capacity || stop.out_of_drive_time
      json.extract! stop, :trace, :out_of_window, :out_of_capacity, :out_of_drive_time
      (json.wait_time "%i:%02i" % [stop.wait_time/60/60, stop.wait_time/60%60]) if stop.wait_time && stop.wait_time > 60
      (json.geocoded true) if stop.destination.lat != nil && stop.destination.lng != nil
      (json.time stop.time.strftime("%H:%M")) if stop.time
      (json.active true) if stop.active
      (json.number number+=1) if stop.active
      json.distance (stop.distance or 0)/1000
      json.destination do
         destination = stop.destination
         json.extract! destination, :id, :ref, :name, :street, :detail, :postalcode, :city, :lat, :lng, :comment, :quantity
         (json.take_over destination.take_over.strftime("%H:%M:%S")) if destination.take_over
         (json.open destination.open.strftime("%H:%M")) if destination.open
         (json.close destination.close.strftime("%H:%M")) if destination.close
         color = destination.tags.find{ |tag| tag.color }
         (json.color color.color) if color
         icon = destination.tags.find{ |tag| tag.icon }
         (json.icon icon.icon) if icon
      end
    end
    json.store_stop do
      json.extract! route.vehicle.store_stop, :id, :name, :street, :postalcode, :city, :lat, :lng
      (json.time route.end.strftime("%H:%M")) if route.end
      json.stop_trace route.stop_trace
      (json.error true) if route.stop_out_of_drive_time
      json.stop_out_of_drive_time route.stop_out_of_drive_time
      json.stop_distance (route.stop_distance or 0)/1000
    end if route.vehicle
    (json.route_no_geocoding no_geocoding) if no_geocoding
    (json.route_out_of_window out_of_window) if out_of_window
    (json.route_out_of_capacity out_of_capacity) if out_of_capacity
    (json.route_out_of_drive_time out_of_drive_time) if out_of_drive_time
    (json.route_error true) if no_geocoding || out_of_window || out_of_capacity || out_of_drive_time
  end
end
