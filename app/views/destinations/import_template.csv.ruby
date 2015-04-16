require 'importer'
CSV.generate { |csv|
  csv << Importer.columns.values
}
