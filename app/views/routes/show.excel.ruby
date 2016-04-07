CSV.generate({col_sep: ';'}) { |csv|
  csv << @columns.map{ |c| I18n.t('plannings.export_file.' + c.to_s) }
  render partial: 'show', formats: [:csv], locals: {route: @route, csv: csv}
}
