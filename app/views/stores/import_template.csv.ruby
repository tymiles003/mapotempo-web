require 'importer_stores'
CSV.generate { |csv|
  csv << ImporterStores.columns.values
}
