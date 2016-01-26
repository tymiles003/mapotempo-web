json.plannings do
  json.array! @order_array.customer.plannings, :id, :name
end

json.products do
  json.array! @order_array.customer.products, :id, :code, :name
end

if params[:planning_id]
  json.vehicle true
end

json.columns @order_array.days.times do |i|
  json.week_day l(@order_array.base_date + i, format: '%a')
  json.date l @order_array.base_date + i
end

json.rows @visits_orders do |visit_orders, vehicle_usage|
  if vehicle_usage
    json.vehicle_name vehicle_usage.vehicle.name
    json.vehicle_color vehicle_usage.vehicle.color
  end
  json.name visit_orders[0].visit.destination.name + (visit_orders[0].visit.destination.visits.size > 1 ? ' - #' + (visit_orders[0].visit.destination.visits.index(visit_orders[0].visit) + 1).to_s + ' ' + (visit_orders[0].visit.ref || '') : '')
  json.comment visit_orders[0].visit.destination.comment
  json.orders visit_orders do |order|
    json.id order.id
    json.product_ids do
      json.array! order.products.collect(&:id)
    end
  end
end
