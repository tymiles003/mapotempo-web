CSV.generate({col_sep: ';'}) { |csv|
  csv << [
    I18n.t('destinations.import_file.name'),
    I18n.t('destinations.import_file.street'),
    I18n.t('destinations.import_file.postalcode'),
    I18n.t('destinations.import_file.city'),
    I18n.t('destinations.import_file.lat'),
    I18n.t('destinations.import_file.lng'),
    I18n.t('destinations.import_file.quantity'),
    I18n.t('destinations.import_file.open'),
    I18n.t('destinations.import_file.close')
  ]
  Destination.where(customer_id: current_user.customer.id).each { |destination|
    csv << [destination.name, destination.street, destination.postalcode, destination.city, destination.lat, destination.lng, destination.quantity, destination.open, destination.close]
  }
}
