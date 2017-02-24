json.stores do
  json.array! @stores do |store|
    json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :geocoding_accuracy, :color, :icon, :icon_size
    json.ref store.ref if @customer.enable_references
  end
end
