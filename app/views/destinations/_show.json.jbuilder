json.extract! destination, :id, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :phone_number, :comment, :geocoding_accuracy, :geocoding_level
json.ref destination.ref if @customer.enable_references
json.geocoding_level_point destination.point?
json.geocoding_level_house destination.house?
json.geocoding_level_street destination.street?
json.geocoding_level_intersection destination.intersection?
json.geocoding_level_city destination.city?
if destination.geocoding_level
  json.geocoding_level_title t('activerecord.attributes.destination.geocoding_level') + ' : ' + t('destinations.form.geocoding_level.' + destination.geocoding_level.to_s)
end
json.tag_ids do
  json.array! destination.tags.collect(&:id)
end
json.has_no_position (destination.lat.nil? || destination.lng.nil?) ? t('destinations.index.no_position') : false
json.visits do
  json.array! destination.visits do |visit|
    json.extract! visit, :id, :quantity
    json.ref visit.ref if @customer.enable_references
    json.take_over visit.take_over && l(visit.take_over, format: :hour_minute_second)
    json.open visit.open && l(visit.open, format: :hour_minute)
    json.close visit.close && l(visit.close, format: :hour_minute)
    json.tag_ids do
      json.array! visit.tags.collect(&:id)
    end
  end
end
