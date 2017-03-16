class ChangeTimeToIntegerToRoutes < ActiveRecord::Migration
  def up
    previous_times = {}
    Route.all.order(:id).each do |route|
      previous_times[route.id] = {
          start: route.start,
          end: route.end
      }
    end

    remove_column :routes, :start
    remove_column :routes, :end
    add_column :routes, :start, :integer
    add_column :routes, :end, :integer

    Route.reset_column_information
    Route.transaction do
      previous_times.each do |route_id, times|
        route = Route.find(route_id)
        route.start = times[:start].seconds_since_midnight.to_i if times[:start]
        route.end = times[:end].seconds_since_midnight.to_i if times[:end]
        route.save!
      end
    end
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
end
