CSV.generate({col_sep: ';'}) { |csv|
  csv << @columns.map{ |c| I18n.t('plannings.export_file.' + c.to_s) }
  @routes.select{ |route| route.stops.size > 0 }.select{ |route|
    route.vehicle_usage || !@params.key?(:stops) || @params[:stops].split('|').include?('out-of-route')
  }.collect { |route|
    render partial: 'routes/show', formats: [:csv], locals: {route: route, csv: csv}
  }.join('')
}
