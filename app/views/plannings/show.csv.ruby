CSV.generate({col_sep: ';'}) { |csv|
  csv << [
    I18n.t('plannings.export_file.route'),
    I18n.t('plannings.export_file.order'),
    I18n.t('plannings.export_file.time'),
    I18n.t('plannings.export_file.distance'),
    I18n.t('plannings.export_file.name'),
    I18n.t('plannings.export_file.street'),
    I18n.t('plannings.export_file.postalcode'),
    I18n.t('plannings.export_file.city')
  ]
  @planning.routes.select { |route|
    route.vehicle
  }.collect { |route|
    render 'routes/show', route: route, csv: csv
  }.join('')
}
