json.extract! store, :ref, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :geocoding_accuracy
json.open store.open && store.open.strftime('%H:%M')
json.close store.close && store.close.strftime('%H:%M')
