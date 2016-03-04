require 'importer_destinations'
CSV.generate({col_sep: ';'}) { |csv|
  [:title, :format, :required, :desc].each{ |row|
    csv << ImporterDestinations.new(current_user.customer).columns.values.collect{ |data| data[:row] }
  }
}
