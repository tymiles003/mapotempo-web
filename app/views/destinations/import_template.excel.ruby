require 'importer_destinations'
CSV.generate({col_sep: ';'}) { |csv|
  csv << ImporterDestinations.new(current_user.customer).columns.values.collect{ |data| data[:title] }
  csv << ImporterDestinations.new(current_user.customer).columns.values.collect{ |data|
    data[:format] + (!data[:required] || data[:required] != I18n.t('destinations.import_file.format.required') ?
    ' (' + (data[:required] ? data[:required] : I18n.t('destinations.import_file.format.optionnal')) + ')' :
    '')
  }
}
