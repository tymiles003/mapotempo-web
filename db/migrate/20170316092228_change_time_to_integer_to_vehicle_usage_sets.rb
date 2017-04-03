class ChangeTimeToIntegerToVehicleUsageSets < ActiveRecord::Migration
  def up
    fake_missing_props

    add_column :vehicle_usage_sets, :open_temp, :integer
    add_column :vehicle_usage_sets, :close_temp, :integer
    add_column :vehicle_usage_sets, :rest_start_temp, :integer
    add_column :vehicle_usage_sets, :rest_stop_temp, :integer
    add_column :vehicle_usage_sets, :rest_duration_temp, :integer
    add_column :vehicle_usage_sets, :service_time_start_temp, :integer
    add_column :vehicle_usage_sets, :service_time_end_temp, :integer

    VehicleUsageSet.connection.schema_cache.clear!
    VehicleUsageSet.reset_column_information

    VehicleUsageSet.find_in_batches do |vehicle_usage_sets|
      vehicle_usage_sets.each do |vehicle_usage_set|
        vehicle_usage_set.open_temp = vehicle_usage_set.open.seconds_since_midnight.to_i if vehicle_usage_set.open
        vehicle_usage_set.close_temp = vehicle_usage_set.close.seconds_since_midnight.to_i if vehicle_usage_set.close
        vehicle_usage_set.rest_start_temp = vehicle_usage_set.rest_start.seconds_since_midnight.to_i if vehicle_usage_set.rest_start
        vehicle_usage_set.rest_stop_temp = vehicle_usage_set.rest_stop.seconds_since_midnight.to_i if vehicle_usage_set.rest_stop
        vehicle_usage_set.rest_duration_temp = vehicle_usage_set.rest_duration.seconds_since_midnight.to_i if vehicle_usage_set.rest_duration
        vehicle_usage_set.service_time_start_temp = vehicle_usage_set.service_time_start.seconds_since_midnight.to_i if vehicle_usage_set.service_time_start
        vehicle_usage_set.service_time_end_temp = vehicle_usage_set.service_time_end.seconds_since_midnight.to_i if vehicle_usage_set.service_time_end
        vehicle_usage_set.save!
      end
    end

    remove_column :vehicle_usage_sets, :open
    remove_column :vehicle_usage_sets, :close
    remove_column :vehicle_usage_sets, :rest_start
    remove_column :vehicle_usage_sets, :rest_stop
    remove_column :vehicle_usage_sets, :rest_duration
    remove_column :vehicle_usage_sets, :service_time_start
    remove_column :vehicle_usage_sets, :service_time_end

    rename_column :vehicle_usage_sets, :open_temp, :open
    rename_column :vehicle_usage_sets, :close_temp, :close
    rename_column :vehicle_usage_sets, :rest_start_temp, :rest_start
    rename_column :vehicle_usage_sets, :rest_stop_temp, :rest_stop
    rename_column :vehicle_usage_sets, :rest_duration_temp, :rest_duration
    rename_column :vehicle_usage_sets, :service_time_start_temp, :service_time_start
    rename_column :vehicle_usage_sets, :service_time_end_temp, :service_time_end
  end

  def down
    add_column :vehicle_usage_sets, :open_temp, :time
    add_column :vehicle_usage_sets, :close_temp, :time
    add_column :vehicle_usage_sets, :rest_start_temp, :time
    add_column :vehicle_usage_sets, :rest_stop_temp, :time
    add_column :vehicle_usage_sets, :rest_duration_temp, :time
    add_column :vehicle_usage_sets, :service_time_start_temp, :time
    add_column :vehicle_usage_sets, :service_time_end_temp, :time

    VehicleUsageSet.connection.schema_cache.clear!
    VehicleUsageSet.reset_column_information

    VehicleUsageSet.find_in_batches do |vehicle_usage_sets|
      vehicle_usage_sets.each do |vehicle_usage_set|
        vehicle_usage_set.open_temp =Time.at(vehicle_usage_set.open).utc.strftime('%H:%M:%S') if vehicle_usage_set.open
        vehicle_usage_set.close_temp = Time.at(vehicle_usage_set.close).utc.strftime('%H:%M:%S') if vehicle_usage_set.close
        vehicle_usage_set.rest_start_temp = Time.at(vehicle_usage_set.rest_start).utc.strftime('%H:%M:%S') if vehicle_usage_set.rest_start
        vehicle_usage_set.rest_stop_temp = Time.at(vehicle_usage_set.rest_stop).utc.strftime('%H:%M:%S') if vehicle_usage_set.rest_stop
        vehicle_usage_set.rest_duration_temp = Time.at(vehicle_usage_set.rest_duration).utc.strftime('%H:%M:%S') if vehicle_usage_set.rest_duration
        vehicle_usage_set.service_time_start_temp = Time.at(vehicle_usage_set.service_time_start).utc.strftime('%H:%M:%S') if vehicle_usage_set.service_time_start
        vehicle_usage_set.service_time_end_temp = Time.at(vehicle_usage_set.service_time_end).utc.strftime('%H:%M:%S') if vehicle_usage_set.service_time_end
        vehicle_usage_set.save!
      end
    end

    remove_column :vehicle_usage_sets, :open
    remove_column :vehicle_usage_sets, :close
    remove_column :vehicle_usage_sets, :rest_start
    remove_column :vehicle_usage_sets, :rest_stop
    remove_column :vehicle_usage_sets, :rest_duration
    remove_column :vehicle_usage_sets, :service_time_start
    remove_column :vehicle_usage_sets, :service_time_end

    rename_column :vehicle_usage_sets, :open_temp, :open
    rename_column :vehicle_usage_sets, :close_temp, :close
    rename_column :vehicle_usage_sets, :rest_start_temp, :rest_start
    rename_column :vehicle_usage_sets, :rest_stop_temp, :rest_stop
    rename_column :vehicle_usage_sets, :rest_duration_temp, :rest_duration
    rename_column :vehicle_usage_sets, :service_time_start_temp, :service_time_start
    rename_column :vehicle_usage_sets, :service_time_end_temp, :service_time_end
  end

  def fake_missing_props
    VehicleUsageSet.class_eval do
      attribute :open, ActiveRecord::Type::Time.new
      attribute :close, ActiveRecord::Type::Time.new
      attribute :rest_start, ActiveRecord::Type::Time.new
      attribute :rest_stop, ActiveRecord::Type::Time.new
      attribute :rest_duration, ActiveRecord::Type::Time.new
      attribute :service_time_start, ActiveRecord::Type::Time.new
      attribute :service_time_end, ActiveRecord::Type::Time.new
    end
  end
end
