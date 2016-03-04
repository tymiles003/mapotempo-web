require 'importer_stores'
CSV.generate({col_sep: ';'}) { |csv|
  [:title, :format, :required, :desc].each{ |row|
    csv << ImporterStores.new(current_user.customer).columns.values.collect{ |data| data[row] }
  }
}
