json.extract! destination, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :comment, :phone_number, :geocoding_accuracy, :geocoding_level
json.destination_id destination.id
json.error destination.lat.nil? || destination.lng.nil?

num_visit = 0
json.visits destination.visits do |visit|
  json.extract! visit, :id, :quantity, :tag_ids
  num_visit += 1
  json.num_visit num_visit if destination.visits.size > 1
  json.ref visit.ref if @customer.enable_references
  take_over = visit.take_over && l(visit.take_over, format: :hour_minute_second)
  json.take_over take_over
  json.duration take_over
  json.open_close visit.open || visit.close
  json.open visit.open && l(visit.open, format: :hour_minute)
  json.close visit.close && l(visit.close, format: :hour_minute)
  if !visit.tags.empty?
    json.tags_present do
      json.tags do
        json.array! visit.tags :label
      end
    end
    color = visit.tags.find(&:color)
    (json.color color.color) if color
    icon = visit.tags.find(&:icon)
    (json.icon icon.icon) if icon
  end
end
