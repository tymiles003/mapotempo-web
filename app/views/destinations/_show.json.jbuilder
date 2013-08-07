json.extract! destination, :id, :name, :street, :postalcode, :city, :lat, :lng, :quantity, :open, :close
json.tags do
  json.array! destination.tags.collect{ |t| t.id }
end
