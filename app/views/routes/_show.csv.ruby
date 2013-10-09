index = -1
route.stops.each { |stop|
  csv << [route.vehicle.name, index+=1, (stop.time.strftime("%H:%M") if stop.time), stop.distance, stop.destination.name, stop.destination.street, stop.destination.postalcode, stop.destination.city]
}
