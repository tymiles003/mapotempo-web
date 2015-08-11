json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng
json.open store.open && store.open.strftime('%H:%M')
json.close store.close && store.close.strftime('%H:%M')
