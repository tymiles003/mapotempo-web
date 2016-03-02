require 'importer_destinations'
CSV.generate { |csv|
  [:title, :format, :required, :help].each{ |row|
    csv << ImporterDestinations.new(current_user.customer).columns.values.collect{ |data| data[row] }
  }
}
