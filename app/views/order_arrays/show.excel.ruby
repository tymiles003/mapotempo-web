CSV.generate({col_sep: ';'}) { |csv|
  render partial: 'show', formats: [:csv], locals: {csv: csv}
}
