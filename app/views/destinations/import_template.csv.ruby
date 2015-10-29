require 'importer_destinations'
CSV.generate { |csv|
  csv << ImporterDestinations.new(current_user.customer).columns.values
}
