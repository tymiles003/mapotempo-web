CSV.generate { |csv|
  csv << @columns.map{ |c| I18n.t('plannings.export_file.' + c.to_s) }
  render 'show', route: @route, csv: csv
}
