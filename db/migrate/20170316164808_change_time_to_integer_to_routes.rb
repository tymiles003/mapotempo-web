class ChangeTimeToIntegerToRoutes < ActiveRecord::Migration
  def up
    fake_missing_props

    add_column :routes, :start_temp, :integer
    add_column :routes, :end_temp, :integer

    Route.connection.schema_cache.clear!
    Route.reset_column_information

    Route.find_in_batches do |routes|
      routes.each do |route|
        route.start_temp = route.start.seconds_since_midnight.to_i if route.start
        route.end_temp = route.end.seconds_since_midnight.to_i if route.end
        route.save!
      end
    end

    remove_column :routes, :start
    remove_column :routes, :end

    rename_column :routes, :start_temp, :start
    rename_column :routes, :end_temp, :end
  end

  def down
    previous_times = {}
    Route.all.order(:id).each do |route|
      previous_times[route.id] = {
          start: route.start,
          end: route.end
      }
    end

    remove_column :routes, :start
    remove_column :routes, :end

    add_column :routes, :start, :time
    add_column :routes, :end, :time

    Route.reset_column_information
    Route.transaction do
      previous_times.each do |route_id, times|
        route = Route.find(route_id)
        route.start = Time.at(times[:start]).utc.strftime('%H:%M:%S') if times[:start]
        route.end = Time.at(times[:end]).utc.strftime('%H:%M:%S') if times[:end]
        route.save!
      end
    end
  end

  def fake_missing_props
    Stop.class_eval do
      attribute :start, ActiveRecord::Type::Time.new
      attribute :end, ActiveRecord::Type::Time.new
    end
  end
end
