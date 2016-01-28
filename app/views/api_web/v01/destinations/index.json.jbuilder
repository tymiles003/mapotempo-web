json.tags do
  json.array! @tags, :id, :label, :color, :icon
end
json.destinations @destinations, partial: 'api_web/v01/destinations/show', as: :destination
json.stores do
  json.array! @stores do |store|
    json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :geocoding_accuracy, :color, :icon, :icon_size
    json.ref store.ref if @customer.enable_references
  end
end
