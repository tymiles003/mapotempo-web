json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
json.store true
(json.manage_store true) if @manage_planning.include?(:store)
if @show_isoline
  json.isoline store.customer.router.isochrone || store.customer.router.isodistance
  json.isochrone store.customer.router.isochrone
  json.isodistance store.customer.router.isodistance
end
