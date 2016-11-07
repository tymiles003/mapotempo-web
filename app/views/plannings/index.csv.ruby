CSV.generate { |csv|
  csv << @columns.map{ |c| I18n.t('plannings.export_file.' + c.to_s) }
  @plannings.each do |planning|
    render partial: "routes/index.csv", formats: [:ruby], locals: { planning: planning, csv: csv }
  end
}
