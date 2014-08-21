json.extract! destination, :ref, :id, :name, :street, :detail, :postalcode, :city, :lat, :lng, :quantity, :comment
json.take_over destination.take_over && destination.take_over.strftime('%H:%M:%S')
json.take_over_default destination.customer && destination.customer.take_over && destination.customer.take_over.strftime('%H:%M:%S')
json.open destination.open && destination.open.strftime('%H:%M')
json.close destination.close && destination.close.strftime('%H:%M')
json.tags do
  json.array! destination.tags.collect{ |t| t.id }
end
