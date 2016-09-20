CSV.generate({col_sep: ';'}) { |csv|
  csv << export_column_titles(@columns)
  @plannings.each do |planning|
    render partial: 'routes/index.excel', formats: [:excel], locals: {planning: planning, csv: csv}
  end
}
