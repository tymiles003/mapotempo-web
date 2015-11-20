require 'importer_destinations'
CSV.generate({col_sep: ';'}) { |csv|
  csv << ImporterDestinations.new(current_user.customer).columns.values
}
