require 'importer_stores'
CSV.generate { |csv|
  [:title, :format, :required, :help].each{ |row|
    csv << ImporterStores.new(current_user.customer).columns.values.collect{ |data| data[row] }
  }
}
