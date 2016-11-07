CSV.generate({col_sep: ';'}) { |csv|
  csv << @columns.map{ |c| I18n.t('plannings.export_file.' + c.to_s) }
  @plannings.each do |planning|
    render partial: 'routes/index.excel', formats: [:excel], locals: {planning: planning, csv: csv}
  end
}
