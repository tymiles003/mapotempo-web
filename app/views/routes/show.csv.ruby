CSV.generate { |csv|
  csv << export_column_titles(@columns)
  render 'show', route: @route, csv: csv
}
