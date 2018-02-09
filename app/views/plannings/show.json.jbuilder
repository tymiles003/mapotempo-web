if Job.on_planning(@planning.customer.job_optimizer, @planning.id)
  json.optimizer do
    json.extract! @planning.customer.job_optimizer, :id, :progress, :attempts
    json.error !!@planning.customer.job_optimizer.failed_at
    json.customer_id @planning.customer.id
    json.dispatch_params_delayed_job do
      json.with_stops @with_stops
      json.route_ids @routes.map(&:id).join(',') if @routes
    end
  end
else
  json.prefered_unit current_user.prefered_unit
  json.extract! @planning, :id, :ref
  json.customer_id @planning.customer.id
  json.customer_enable_external_callback current_user.customer.enable_external_callback
  json.customer_external_callback_name current_user.customer.external_callback_name
  json.customer_external_callback_url current_user.customer.external_callback_url
  duration = @planning.routes.includes_vehicle_usages.select(&:vehicle_usage).to_a.sum(0){ |route| route.end && route.start ? route.end - route.start : 0 }
  json.duration time_over_day(duration)
  json.distance locale_distance(@planning.routes.to_a.sum(0){ |route| route.distance || 0 }, current_user.prefered_unit)
  json.emission number_to_human(@planning.routes.to_a.sum(0){ |route| route.emission || 0 }, precision: 4)
  (json.outdated true) if @planning.outdated
  json.size @planning.routes.to_a.sum(0){ |route| route.stops.size }
  json.size_active @planning.routes.to_a.sum(0){ |route| route.vehicle_usage_id ? route.size_active : 0 }
  json.stores (@planning.vehicle_usage_set.vehicle_usages.collect(&:default_store_start) + @planning.vehicle_usage_set.vehicle_usages.collect(&:default_store_stop) + @planning.vehicle_usage_set.vehicle_usages.collect(&:default_store_rest)).compact.uniq do |store|
    json.extract! store, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
  end

  averages = @planning.averages(current_user.prefered_unit)
  if averages
    json.averages do
      json.routes_visits_duration time_over_day(averages[:routes_visits_duration]) if averages[:routes_visits_duration]
      json.routes_drive_time time_over_day(averages[:routes_drive_time])
      json.routes_wait_time time_over_day(averages[:routes_wait_time]) if averages[:routes_wait_time]
      json.routes_speed_average averages[:routes_speed_average]
      json.vehicles_used averages[:vehicles_used]
      json.vehicles averages[:vehicles]
      json.total_quantities planning_quantities(@planning)
    end
  end

  json.routes (@routes || (@with_stops ? @planning.routes.includes_destinations : @planning.routes)), partial: 'routes/edit', as: :route, locals: { list_devices: devices(@planning.customer) }
end
