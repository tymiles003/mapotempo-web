if @planning.customer.job_optimizer
  json.optimizer do
    json.extract! @planning.customer.job_optimizer, :id, :progress, :attempts
    json.error !!@planning.customer.job_optimizer.failed_at
    json.customer_id @planning.customer.id
  end
else
  json.extract! @planning, :id, :ref
  json.customer_id @planning.customer.id
  json.customer_enable_external_callback current_user.customer.enable_external_callback
  json.customer_external_callback_name current_user.customer.external_callback_name
  json.customer_external_callback_url current_user.customer.external_callback_url
  duration = @planning.routes.select(&:vehicle_usage).to_a.sum(0){ |route| route.end && route.start ? route.end - route.start : 0 }
  json.duration '%i:%02i' % [duration / 60 / 60, duration / 60 % 60]
  json.distance number_to_human(@planning.routes.to_a.sum(0){ |route| route.distance || 0 }, units: :distance, precision: 3, format: '%n %u')
  json.emission number_to_human(@planning.routes.to_a.sum(0){ |route| route.emission || 0 }, precision: 4)
  (json.out_of_date true) if @planning.out_of_date
  json.size @planning.routes.to_a.sum(0){ |route| route.stops.size }
  json.size_active @planning.routes.to_a.sum(0){ |route| route.vehicle_usage ? route.size_active : 0 }
  json.stores (@planning.vehicle_usage_set.vehicle_usages.collect(&:default_store_start) + @planning.vehicle_usage_set.vehicle_usages.collect(&:default_store_stop) + @planning.vehicle_usage_set.vehicle_usages.collect(&:default_store_rest)).compact.uniq do |store|
    json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
  end
  json.routes (@routes || @planning.routes), partial: 'routes/edit', as: :route
end
