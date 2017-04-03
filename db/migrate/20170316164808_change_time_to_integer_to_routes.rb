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
    add_column :routes, :start_temp, :time
    add_column :routes, :end_temp, :time

    Route.connection.schema_cache.clear!
    Route.reset_column_information

    Route.find_in_batches do |routes|
      routes.each do |route|
        route.start_temp = Time.at(times[:start]).utc.strftime('%H:%M:%S') if route.start
        route.end_temp = Time.at(times[:end]).utc.strftime('%H:%M:%S') if route.end
        route.save!
      end
    end

    remove_column :routes, :start
    remove_column :routes, :end

    add_column :routes, :start, :time
    add_column :routes, :end, :time
  end

  def fake_missing_props
    Route.class_eval do
      attribute :start, ActiveRecord::Type::Time.new
      attribute :end, ActiveRecord::Type::Time.new
    end
  end
end
