require 'importer_stores'
CSV.generate({col_sep: ';'}) { |csv|
  csv << ImporterStores.new(current_user.customer).columns.values
}
