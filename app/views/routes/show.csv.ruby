CSV.generate({col_sep: ';'}) { |csv|
  csv << [
    I18n.t('plannings.export_file.route'),
    I18n.t('plannings.export_file.order'),
    I18n.t('plannings.export_file.time'),
    I18n.t('plannings.export_file.distance'),
    I18n.t('plannings.export_file.name'),
    I18n.t('plannings.export_file.street'),
    I18n.t('plannings.export_file.detail'),
    I18n.t('plannings.export_file.postalcode'),
    I18n.t('plannings.export_file.city'),
    I18n.t('plannings.export_file.comment')
  ]
  render 'show', route: @route, csv: csv
}
