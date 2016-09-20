CSV.generate { |csv|
  csv << export_column_titles(@columns)
  render partial: "routes/index.csv", formats: [:csv], locals: { planning: @planning, csv: csv }
}
