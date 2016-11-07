  planning.routes.select{ |route| route.stops.size > 0 }.select{ |route|
  route.vehicle_usage || !@params.key?(:stops) || @params[:stops].split('|').include?('out-of-route')
  }.collect { |route|
    render 'routes/show', route: route, csv: csv
  }.join('')
