require 'importer_destinations'
CSV.generate { |csv|
  [:title, :format, :required, :desc].each{ |row|
    csv << ImporterDestinations.new(current_user.customer).columns.values.collect{ |data| data[row] }
  }
}
