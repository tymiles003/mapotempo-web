json.extract! destination, :ref, :id, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :quantity, :comment, :geocoding_accuracy, :tag_ids
json.take_over destination.take_over && destination.take_over.strftime('%H:%M:%S')
json.open destination.open && destination.open.strftime('%H:%M')
json.close destination.close && destination.close.strftime('%H:%M')
