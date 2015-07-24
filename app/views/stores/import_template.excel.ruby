require 'importer_stores'
CSV.generate({col_sep: ';'}) { |csv|
  csv << ImporterStores.columns.values
}
