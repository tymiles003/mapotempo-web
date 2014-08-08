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
  json.distance number_to_human(@planning.routes.to_a.sum(0){ |route| route.distance or 0 }, units: :distance, precision: 3)
  json.emission number_to_human(@planning.routes.to_a.sum(0){ |route| route.emission or 0 }, precision: 4)
  (json.out_of_date true) if @planning.out_of_date
  (json.zoning_out_of_date true) if @planning.zoning_out_of_date
  json.size @planning.routes.to_a.sum(0){ |route| route.vehicle ? route.size : 0 }
  json.store do
    json.lat current_user.customer.store.lat
    json.lng current_user.customer.store.lng
    json.icon asset_path("marker-home.svg")
  end
  json.routes @planning.routes do |route|
    json.route_id route.id
    (json.duration "%i:%02i" % [(route.end - route.start)/60/60, (route.end - route.start)/60%60]) if route.start && route.end
    (json.hidden true) if route.hidden
    (json.locked) if route.locked
    json.distance number_to_human((route.distance or 0), units: :distance, precision: 3)
    json.size route.size
    json.quantity route.quantity
    if route.vehicle
      json.vehicle_id route.vehicle.id
      json.icon asset_path("point-#{route.vehicle.color.gsub('#','')}.svg")
      json.work_time "%i:%02i" % [(route.vehicle.close - route.vehicle.open)/60/60, (route.vehicle.close - route.vehicle.open)/60%60]
      (json.tomtom true) if route.vehicle.tomtom_id && !route.vehicle.customer.tomtom_account.blank? && !route.vehicle.customer.tomtom_user.blank? && !route.vehicle.customer.tomtom_password.blank?
    end
    number = 0
    no_geocoding = out_of_window = out_of_capacity = out_of_drive_time = false
    json.stops route.stops do |stop|
      if stop.destination == current_user.customer.store
        json.is_store true
      end
      out_of_window |= stop.out_of_window
      out_of_capacity |= stop.out_of_capacity
      out_of_drive_time |= stop.out_of_drive_time
      no_geocoding |= !stop.destination.lat
      (json.error true) if !stop.destination.lat || stop.out_of_window || stop.out_of_capacity || stop.out_of_drive_time
      json.extract! stop, :trace, :out_of_window, :out_of_capacity, :out_of_drive_time
      (json.no_geocoding true) if !stop.destination.lat
      (json.time stop.time.strftime("%H:%M")) if stop.time
      (json.active true) if stop.active
      (json.number number+=1) if stop.active && stop.destination != current_user.customer.store
      json.distance (stop.distance or 0)/1000
      json.destination do
         destination = stop.destination
         json.extract! destination, :id, :ref, :name, :street, :detail, :postalcode, :city, :lat, :lng, :comment, :quantity
         (json.open destination.open.strftime("%H:%M")) if destination.open
         (json.close destination.close.strftime("%H:%M")) if destination.close
      end
      json.type (stop.destination==current_user.customer.store)? 'store' : 'waypoint'
    end
    (json.route_no_geocoding no_geocoding) if no_geocoding
    (json.route_out_of_window out_of_window) if out_of_window
    (json.route_out_of_capacity out_of_capacity) if out_of_capacity
    (json.route_out_of_drive_time out_of_drive_time) if out_of_drive_time
    (json.route_error true) if no_geocoding || out_of_window || out_of_capacity || out_of_drive_time
  end
end
