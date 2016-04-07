CSV.generate { |csv|
  csv << @columns.map{ |c| I18n.t('plannings.export_file.' + c.to_s) }
  @planning.routes.select { |route|
    !route.vehicle_usage || route.stops.size > 0
  }.collect { |route|
    render 'routes/show', route: route, csv: csv
  }.join('')
}
