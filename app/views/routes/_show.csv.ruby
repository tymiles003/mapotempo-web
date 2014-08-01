index = -1
route.stops.each { |stop|
  csv << [
    route.vehicle.name,
    index+=1,
    (stop.time.strftime("%H:%M") if stop.time),
    stop.distance,
    stop.destination.ref,
    stop.destination.name,
    stop.destination.street,
    stop.destination.detail,
    stop.destination.postalcode,
    stop.destination.city,
    stop.destination.lat,
    stop.destination.lng,
    stop.destination.comment,
    stop.destination.quantity,
    stop.active ? '1' : '0',
    (stop.destination.open.strftime("%H:%M") if stop.destination.open),
    (stop.destination.close.strftime("%H:%M") if stop.destination.close),
    stop.destination.tags.collect(&:label).join(','),
    stop.out_of_window ? 'x' : '',
    stop.out_of_capacity ? 'x' : '',
    stop.out_of_drive_time ? 'x' : ''
  ]
}
