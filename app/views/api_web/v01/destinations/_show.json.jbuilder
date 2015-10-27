json.extract! destination, :ref, :id, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :quantity, :comment, :phone_number, :geocoding_accuracy, :geocoding_level, :tag_ids
json.take_over destination.take_over && destination.take_over.strftime('%H:%M:%S')
json.open destination.open && destination.open.strftime('%H:%M')
json.close destination.close && destination.close.strftime('%H:%M')
json.destination do
  json.id destination.id
  if !destination.tags.empty?
    json.tags_present do
      json.tags do
        json.array! destination.tags do |tag|
          json.extract! tag, :label
        end
      end
    end
  end
  (json.duration destination.take_over.strftime('%H:%M:%S')) if destination.take_over
  color = destination.tags.find(&:color)
  (json.color color.color) if color
  icon = destination.tags.find(&:icon)
  (json.icon icon.icon) if icon
end
json.error destination.lat.nil? || destination.lng.nil?
