CSV.generate({col_sep: ';'}) { |csv|
  csv << [
    I18n.t('destinations.import_file.ref'),
    I18n.t('destinations.import_file.name'),
    I18n.t('destinations.import_file.street'),
    I18n.t('destinations.import_file.detail'),
    I18n.t('destinations.import_file.postalcode'),
    I18n.t('destinations.import_file.city'),
    I18n.t('destinations.import_file.country'),
    I18n.t('destinations.import_file.lat'),
    I18n.t('destinations.import_file.lng'),
    I18n.t('destinations.import_file.geocoding_accuracy'),
    I18n.t('destinations.import_file.geocoding_level'),
    I18n.t('destinations.import_file.take_over'),
    I18n.t('destinations.import_file.quantity'),
    I18n.t('destinations.import_file.open'),
    I18n.t('destinations.import_file.close'),
    I18n.t('destinations.import_file.comment'),
    I18n.t('destinations.import_file.tags')
  ]
  @destinations.each { |destination|
    csv << [
      destination.ref,
      destination.name,
      destination.street,
      destination.detail,
      destination.postalcode,
      destination.city,
      destination.country,
      destination.lat,
      destination.lng,
      destination.geocoding_accuracy,
      destination.geocoding_level,
      destination.take_over && destination.take_over.strftime('%H:%M:%S'),
      destination.quantity,
      destination.open && destination.open.strftime('%H:%M'),
      destination.close && destination.close.strftime('%H:%M'),
      destination.comment,
      destination.tags.collect(&:label).join(',')
    ]
  }
}
