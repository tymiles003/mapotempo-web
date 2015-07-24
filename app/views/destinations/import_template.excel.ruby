require 'importer_destinations'
CSV.generate({col_sep: ';'}) { |csv|
  csv << ImporterDestinations.columns.values
}
