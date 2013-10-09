CSV.generate({col_sep: ';'}) { |csv|
  csv << [:route, :ordrer, :time, :distance, :name, :street, :postalcode, :city]
  render 'show', route: @route, csv: csv
}
