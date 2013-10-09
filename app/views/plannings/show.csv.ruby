CSV.generate({col_sep: ';'}) { |csv|
  csv << [:route, :ordrer, :time, :distance, :name, :street, :postalcode, :city]
  @planning.routes.select { |route|
    route.vehicle
  }.collect { |route|
    render 'routes/show', route: route, csv: csv
  }.join('')
}
