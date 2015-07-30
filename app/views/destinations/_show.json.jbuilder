json.extract! destination, :ref, :id, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :quantity, :comment, :geocoding_accuracy
json.take_over destination.take_over && destination.take_over.strftime('%H:%M:%S')
json.open destination.open && destination.open.strftime('%H:%M')
json.close destination.close && destination.close.strftime('%H:%M')
json.tag_ids do
  json.array! destination.tags.collect(&:id)
end
json.has_error destination.lat.nil? || destination.lng.nil?
