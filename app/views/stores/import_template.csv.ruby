require 'importer_stores'
CSV.generate { |csv|
  csv << ImporterStores.new.columns.values
}
