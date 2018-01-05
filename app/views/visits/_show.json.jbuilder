json.destination true

json.extract! @visit.destination, :name, :street, :detail, :postalcode, :city, :country, :comment, :phone_number, :lat, :lng
json.ref @visit.ref || @visit.destination.ref if @visit.destination.customer.enable_references
json.open_close1 @visit.open1 || @visit.close1
(json.open1 @visit.open1_time) if @visit.open1
(json.open1_day number_of_days(@visit.open1)) if @visit.open1
(json.close1 @visit.close1_time) if @visit.close1
(json.close1_day number_of_days(@visit.close1)) if @visit.close1
json.open_close2 @visit.open2 || @visit.close2
(json.open2 @visit.open2_time) if @visit.open2
(json.open2_day number_of_days(@visit.open2)) if @visit.open2
(json.close2 @visit.close2_time) if @visit.close2
(json.close2_day number_of_days(@visit.close2)) if @visit.close2
(json.priority @visit.priority) if @visit.priority
(json.link_phone_number current_user.link_phone_number) if current_user.url_click2call
json.visits true
json.visit_id @visit.id
json.destination_id @visit.destination.id
json.color @visit.default_color
tags = @visit.destination.tags | @visit.tags
if !tags.empty?
  json.tags_present do
    json.tags do
      json.array! tags, :label
    end
  end
end
unless @visit.destination.customer.enable_orders
  json.quantities visit_quantities(@visit, nil) do |units|
    json.quantity units[:quantity] if units[:quantity]
    json.unit_icon units[:unit_icon]
  end
end
json.duration = @visit.default_take_over_time_with_seconds
