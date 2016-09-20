CSV.generate({col_sep: ';'}) { |csv|
  csv << export_column_titles(@columns)
  render partial: 'routes/index.excel', formats: [:csv], locals: {planning: @planning, csv: csv}
}
