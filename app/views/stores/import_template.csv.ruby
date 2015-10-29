require 'importer_stores'
CSV.generate { |csv|
  csv << ImporterStores.new(current_user.customer).columns.values
}
