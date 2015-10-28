require 'importer_destinations'
CSV.generate { |csv|
  csv << ImporterDestinations.new.columns.values
}
