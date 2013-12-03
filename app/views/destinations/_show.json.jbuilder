json.extract! destination, :id, :name, :street, :postalcode, :city, :lat, :lng, :quantity
json.open destination.open && destination.open.strftime('%H:%M')
json.close destination.close && destination.close.strftime('%H:%M')
json.tags do
  json.array! destination.tags.collect{ |t| t.id }
end
