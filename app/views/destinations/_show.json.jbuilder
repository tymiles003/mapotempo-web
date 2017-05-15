json.extract! destination, :id, :name, :street, :detail, :postalcode, :city, :country, :lat, :lng, :phone_number, :comment, :geocoding_accuracy, :geocoding_level
json.ref destination.ref if @customer.enable_references
json.geocoding_level_point destination.point?
json.geocoding_level_house destination.house?
json.geocoding_level_street destination.street?
json.geocoding_level_intersection destination.intersection?
json.geocoding_level_city destination.city?
if destination.geocoding_level
  json.geocoding_level_title t('activerecord.attributes.destination.geocoding_level') + ' : ' + t("destinations.form.geocoding_level.#{destination.geocoding_level.to_s}")
end
json.tag_ids do
  json.array! destination.tags.collect(&:id)
end
json.has_no_position !destination.position? ? t('destinations.index.no_position') : false
json.visits do
  json.array! destination.visits do |visit|
    json.extract! visit, :id
    json.ref visit.ref if @customer.enable_references
    json.take_over visit.take_over_time
    json.duration visit.default_take_over_time_with_seconds
    unless @customer.enable_orders
      if @customer.deliverable_units.size == 1
        json.quantity visit.quantities && visit.quantities[@customer.deliverable_units[0].id]
        json.quantity_default @customer.deliverable_units[0].default_quantity
      elsif visit.default_quantities.values.compact.size > 1
        json.multiple_quantities true
      end
      # Hash { id, quantity, icon, label } for deliverable units
      json.quantities visit_quantities(visit, {})
    end
    json.open1 visit.open1_absolute_time
    json.open1_day number_of_days(visit.open1)
    json.close1 visit.close1_absolute_time
    json.close1_day number_of_days(visit.close1)
    json.open2 visit.open2_absolute_time
    json.open2_day number_of_days(visit.open2)
    json.close2 visit.close2_absolute_time
    json.close2_day number_of_days(visit.close2)
    json.tag_ids do
      json.array! visit.tags.collect(&:id)
    end
  end
end
