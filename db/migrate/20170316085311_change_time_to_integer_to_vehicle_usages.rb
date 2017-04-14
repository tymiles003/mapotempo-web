class ChangeTimeToIntegerToVehicleUsages < ActiveRecord::Migration
  def up
    fake_missing_props

    add_column :vehicle_usages, :open_temp, :integer
    add_column :vehicle_usages, :close_temp, :integer
    add_column :vehicle_usages, :rest_start_temp, :integer
    add_column :vehicle_usages, :rest_stop_temp, :integer
    add_column :vehicle_usages, :rest_duration_temp, :integer
    add_column :vehicle_usages, :service_time_start_temp, :integer
    add_column :vehicle_usages, :service_time_end_temp, :integer

    VehicleUsage.connection.schema_cache.clear!
    VehicleUsage.reset_column_information

    VehicleUsage.transaction do
      VehicleUsage.find_in_batches do |vehicle_usages|
        vehicle_usages.each do |vehicle_usage|
          vehicle_usage.open_temp = vehicle_usage.open.seconds_since_midnight.to_i if vehicle_usage.open
          vehicle_usage.close_temp = vehicle_usage.close.seconds_since_midnight.to_i if vehicle_usage.close
          vehicle_usage.rest_start_temp = vehicle_usage.rest_start.seconds_since_midnight.to_i if vehicle_usage.rest_start
          vehicle_usage.rest_stop_temp = vehicle_usage.rest_stop.seconds_since_midnight.to_i if vehicle_usage.rest_stop
          vehicle_usage.rest_duration_temp = vehicle_usage.rest_duration.seconds_since_midnight.to_i if vehicle_usage.rest_duration
          vehicle_usage.service_time_start_temp = vehicle_usage.service_time_start.seconds_since_midnight.to_i if vehicle_usage.service_time_start
          vehicle_usage.service_time_end_temp = vehicle_usage.service_time_end.seconds_since_midnight.to_i if vehicle_usage.service_time_end
          vehicle_usage.save!(validate: false)
        end
      end
    end

    remove_column :vehicle_usages, :open
    remove_column :vehicle_usages, :close
    remove_column :vehicle_usages, :rest_start
    remove_column :vehicle_usages, :rest_stop
    remove_column :vehicle_usages, :rest_duration
    remove_column :vehicle_usages, :service_time_start
    remove_column :vehicle_usages, :service_time_end

    rename_column :vehicle_usages, :open_temp, :open
    rename_column :vehicle_usages, :close_temp, :close
    rename_column :vehicle_usages, :rest_start_temp, :rest_start
    rename_column :vehicle_usages, :rest_stop_temp, :rest_stop
    rename_column :vehicle_usages, :rest_duration_temp, :rest_duration
    rename_column :vehicle_usages, :service_time_start_temp, :service_time_start
    rename_column :vehicle_usages, :service_time_end_temp, :service_time_end
  end

  def down
    add_column :vehicle_usages, :open_temp, :time
    add_column :vehicle_usages, :close_temp, :time
    add_column :vehicle_usages, :rest_start_temp, :time
    add_column :vehicle_usages, :rest_stop_temp, :time
    add_column :vehicle_usages, :rest_duration_temp, :time
    add_column :vehicle_usages, :service_time_start_temp, :time
    add_column :vehicle_usages, :service_time_end_temp, :time

    VehicleUsage.connection.schema_cache.clear!
    VehicleUsage.reset_column_information

    VehicleUsage.transaction do
      VehicleUsage.find_in_batches do |vehicle_usages|
        vehicle_usages.each do |vehicle_usage|
          vehicle_usage.open_temp =Time.at(vehicle_usage.open).utc.strftime('%H:%M:%S') if vehicle_usage.open
          vehicle_usage.close_temp = Time.at(vehicle_usage.close).utc.strftime('%H:%M:%S') if vehicle_usage.close
          vehicle_usage.rest_start_temp = Time.at(vehicle_usage.rest_start).utc.strftime('%H:%M:%S') if vehicle_usage.rest_start
          vehicle_usage.rest_stop_temp = Time.at(vehicle_usage.rest_stop).utc.strftime('%H:%M:%S') if vehicle_usage.rest_stop
          vehicle_usage.rest_duration_temp = Time.at(vehicle_usage.rest_duration).utc.strftime('%H:%M:%S') if vehicle_usage.rest_duration
          vehicle_usage.service_time_start_temp = Time.at(vehicle_usage.service_time_start).utc.strftime('%H:%M:%S') if vehicle_usage.service_time_start
          vehicle_usage.service_time_end_temp = Time.at(vehicle_usage.service_time_end).utc.strftime('%H:%M:%S') if vehicle_usage.service_time_end
          vehicle_usage.save!(validate: false)
        end
      end
    end

    remove_column :vehicle_usages, :open
    remove_column :vehicle_usages, :close
    remove_column :vehicle_usages, :rest_start
    remove_column :vehicle_usages, :rest_stop
    remove_column :vehicle_usages, :rest_duration
    remove_column :vehicle_usages, :service_time_start
    remove_column :vehicle_usages, :service_time_end

    rename_column :vehicle_usages, :open_temp, :open
    rename_column :vehicle_usages, :close_temp, :close
    rename_column :vehicle_usages, :rest_start_temp, :rest_start
    rename_column :vehicle_usages, :rest_stop_temp, :rest_stop
    rename_column :vehicle_usages, :rest_duration_temp, :rest_duration
    rename_column :vehicle_usages, :service_time_start_temp, :service_time_start
    rename_column :vehicle_usages, :service_time_end_temp, :service_time_end
  end

  def fake_missing_props
    VehicleUsage.class_eval do
      attribute :open, ActiveRecord::Type::Time.new
      attribute :close, ActiveRecord::Type::Time.new
      attribute :rest_start, ActiveRecord::Type::Time.new
      attribute :rest_stop, ActiveRecord::Type::Time.new
      attribute :rest_duration, ActiveRecord::Type::Time.new
      attribute :service_time_start, ActiveRecord::Type::Time.new
      attribute :service_time_end, ActiveRecord::Type::Time.new

      skip_callback :update, :before, :update_tags
    end
  end
end
