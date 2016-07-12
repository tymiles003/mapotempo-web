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
    I18n.t('destinations.import_file.comment'),
    I18n.t('destinations.import_file.phone_number'),
    I18n.t('destinations.import_file.tags'),
    I18n.t('destinations.import_file.without_visit'),
    I18n.t('destinations.import_file.ref_visit'),
    I18n.t('destinations.import_file.take_over'),
    I18n.t('destinations.import_file.quantity1_1'),
    I18n.t('destinations.import_file.quantity1_2'),
    I18n.t('destinations.import_file.open1'),
    I18n.t('destinations.import_file.close1'),
    I18n.t('destinations.import_file.open2'),
    I18n.t('destinations.import_file.close2'),
    I18n.t('destinations.import_file.tags_visit')
  ]
  @destinations.each { |destination|
    destination_columns = [
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
      destination.comment,
      destination.phone_number,
      destination.tags.collect(&:label).join(',')
    ]
    if destination.visits.size > 0
      destination.visits.each { |visit|
        csv << destination_columns + [
          '',
          visit.ref,
          visit.take_over && l(visit.take_over.utc, format: :hour_minute_second),
          visit.quantity1_1,
          visit.quantity1_2,
          visit.open1 && l(visit.open1.utc, format: :hour_minute),
          visit.close1 && l(visit.close1.utc, format: :hour_minute),
          visit.open2 && l(visit.open2.utc, format: :hour_minute),
          visit.close2 && l(visit.close2.utc, format: :hour_minute),
          visit.tags.collect(&:label).join(',')
        ]
      }
    else
      csv << destination_columns + ['x']
    end
  }
}
