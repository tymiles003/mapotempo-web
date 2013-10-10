CSV.generate({col_sep: ';'}) { |csv|
  csv << [:name, :street, :postalcode, :city, :lat, :lng, :quantity, :open, :close]
  Destination.where(customer_id: current_user.customer.id).each { |destination|
    csv << [destination.name, destination.street, destination.postalcode, destination.city, destination.lat, destination.lng, destination.quantity, destination.open, destination.close]
  }
}
