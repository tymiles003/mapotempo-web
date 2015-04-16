require 'importer'
CSV.generate({col_sep: ';'}) { |csv|
  csv << Importer.columns.values
}
