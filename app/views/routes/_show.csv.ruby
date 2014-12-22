if route.vehicle
  csv << [
    (route.vehicle.name if route.vehicle),
    route.ref,
    0,
    nil,
    (route.start.strftime("%H:%M") if route.start),
    0,
    nil,
    route.vehicle.store_start.name,
    route.vehicle.store_start.street,
    nil,
    route.vehicle.store_start.postalcode,
    route.vehicle.store_start.city,
    route.vehicle.store_start.lat,
    route.vehicle.store_start.lng,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil
  ]
end

index = 0
route.stops.each { |stop|
  order = stop.order
  csv << [
    (route.vehicle.name if route.vehicle),
    route.ref,
    (index+=1 if route.vehicle),
    ("%i:%02i" % [stop.wait_time/60/60, stop.wait_time/60%60] if route.vehicle && stop.wait_time),
    (stop.time.strftime("%H:%M") if route.vehicle && stop.time),
    (stop.distance if route.vehicle),
    stop.destination.ref,
    stop.destination.name,
    stop.destination.street,
    stop.destination.detail,
    stop.destination.postalcode,
    stop.destination.city,
    stop.destination.lat,
    stop.destination.lng,
    stop.destination.comment,
    (stop.destination.take_over.strftime("%H:%M:%S") if stop.destination.take_over),
    route.planning.customer.enable_orders ? (order && order.products.length > 0 ? order.products.collect(&:code).join('/') : nil) : stop.destination.quantity,
    ((stop.active ? '1' : '0') if route.vehicle),
    (stop.destination.open.strftime("%H:%M") if stop.destination.open),
    (stop.destination.close.strftime("%H:%M") if stop.destination.close),
    stop.destination.tags.collect(&:label).join('/'),
    stop.out_of_window ? 'x' : '',
    stop.out_of_capacity ? 'x' : '',
    stop.out_of_drive_time ? 'x' : ''
  ]
}

if route.vehicle
  csv << [
    (route.vehicle.name if route.vehicle),
    route.ref,
    index+1,
    nil,
    (route.end.strftime("%H:%M") if route.end),
    route.stop_distance,
    nil,
    route.vehicle.store_stop.name,
    route.vehicle.store_stop.street,
    nil,
    route.vehicle.store_stop.postalcode,
    route.vehicle.store_stop.city,
    route.vehicle.store_stop.lat,
    route.vehicle.store_stop.lng,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    route.stop_out_of_drive_time ? 'x' : ''
  ]
end
