CSV.generate { |csv|
  render 'show', csv: csv
}
