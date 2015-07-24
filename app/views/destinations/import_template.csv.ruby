require 'importer_destinations'
CSV.generate { |csv|
  csv << ImporterDestinations.columns.values
}
