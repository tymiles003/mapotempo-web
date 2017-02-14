json.extract! destination, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :comment, :phone_number, :geocoding_accuracy, :geocoding_level
json.destination_id destination.id
json.error !destination.position?

tags = destination.tags
json.visits destination.visits do |visit|
  json.extract! visit, :id, :tag_ids
  json.quantities visit_quantities(visit, nil) do |units|
    json.quantity units[:quantity] if units[:quantity]
  end
  json.index_visit (destination.visits.index(visit) + 1) if destination.visits.size > 1
  json.ref visit.ref if @customer.enable_references
  take_over = visit.take_over && l(visit.take_over.utc, format: :hour_minute_second)
  json.take_over take_over
  json.duration take_over
  json.open_close1 visit.open1 || visit.close1
  json.open1 visit.open1 && l(visit.open1.utc, format: :hour_minute)
  json.close1 visit.close1 && l(visit.close1.utc, format: :hour_minute)
  json.open_close2 visit.open2 || visit.close2
  json.open2 visit.open2 && l(visit.open2.utc, format: :hour_minute)
  json.close2 visit.close2 && l(visit.close2.utc, format: :hour_minute)
  tags = visit.tags | destination.tags
  if !tags.empty?
    json.tags_present do
      json.tags do
        json.array! tags, :label
      end
    end
  end
end
if destination.visits.empty?
  if !tags.empty?
    json.tags_present do
      json.tags do
        json.array! tags, :label
      end
    end
  end
end
# TODO: display several icons
(json.color destination.visits_color) if destination.visits_color
(json.icon destination.visits_icon) if destination.visits_icon
