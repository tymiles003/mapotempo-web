class ChangeTimeToIntegerToVehicleUsageSets < ActiveRecord::Migration
  def up
    previous_times = {}
    VehicleUsageSet.all.order(:id).each do |vehicle_usage_set|
      previous_times[vehicle_usage_set.id] = {
          open: vehicle_usage_set.open,
          close: vehicle_usage_set.close,
          rest_start: vehicle_usage_set.rest_start,
          rest_stop: vehicle_usage_set.rest_stop,
          rest_duration: vehicle_usage_set.rest_duration,
          service_time_start: vehicle_usage_set.service_time_start,
          service_time_end: vehicle_usage_set.service_time_end
      }
    end

    remove_column :vehicle_usage_sets, :open
    remove_column :vehicle_usage_sets, :close
    remove_column :vehicle_usage_sets, :rest_start
    remove_column :vehicle_usage_sets, :rest_stop
    remove_column :vehicle_usage_sets, :rest_duration
    remove_column :vehicle_usage_sets, :service_time_start
    remove_column :vehicle_usage_sets, :service_time_end
    add_column :vehicle_usage_sets, :open, :integer
    add_column :vehicle_usage_sets, :close, :integer
    add_column :vehicle_usage_sets, :rest_start, :integer
    add_column :vehicle_usage_sets, :rest_stop, :integer
    add_column :vehicle_usage_sets, :rest_duration, :integer
    add_column :vehicle_usage_sets, :service_time_start, :integer
    add_column :vehicle_usage_sets, :service_time_end, :integer

    VehicleUsageSet.reset_column_information
    VehicleUsageSet.transaction do
      previous_times.each do |vehicle_usage_set_id, times|
        vehicle_usage_set = VehicleUsageSet.find(vehicle_usage_set_id)
        vehicle_usage_set.open = times[:open].seconds_since_midnight.to_i if times[:open]
        vehicle_usage_set.close = times[:close].seconds_since_midnight.to_i if times[:close]
        vehicle_usage_set.rest_start = times[:rest_start].seconds_since_midnight.to_i if times[:rest_start]
        vehicle_usage_set.rest_stop = times[:rest_stop].seconds_since_midnight.to_i if times[:rest_stop]
        vehicle_usage_set.rest_duration = times[:rest_duration].seconds_since_midnight.to_i if times[:rest_duration]
        vehicle_usage_set.service_time_start = times[:service_time_start].seconds_since_midnight.to_i if times[:service_time_start]
        vehicle_usage_set.service_time_end = times[:service_time_end].seconds_since_midnight.to_i if times[:service_time_end]
        vehicle_usage_set.save!
      end
    end
  end

  def down
    previous_times = {}
    VehicleUsageSet.all.order(:id).each do |vehicle_usage_set|
      previous_times[vehicle_usage_set.id] = {
          open: vehicle_usage_set.open,
          close: vehicle_usage_set.close,
          rest_start: vehicle_usage_set.rest_start,
          rest_stop: vehicle_usage_set.rest_stop,
          rest_duration: vehicle_usage_set.rest_duration,
          service_time_start: vehicle_usage_set.service_time_start,
          service_time_end: vehicle_usage_set.service_time_end
      }
    end

    remove_column :vehicle_usage_sets, :open
    remove_column :vehicle_usage_sets, :close
    remove_column :vehicle_usage_sets, :rest_start
    remove_column :vehicle_usage_sets, :rest_stop
    remove_column :vehicle_usage_sets, :rest_duration
    remove_column :vehicle_usage_sets, :service_time_start
    remove_column :vehicle_usage_sets, :service_time_end
    add_column :vehicle_usage_sets, :open, :time
    add_column :vehicle_usage_sets, :close, :time
    add_column :vehicle_usage_sets, :rest_start, :time
    add_column :vehicle_usage_sets, :rest_stop, :time
    add_column :vehicle_usage_sets, :rest_duration, :time
    add_column :vehicle_usage_sets, :service_time_start, :time
    add_column :vehicle_usage_sets, :service_time_end, :time

    VehicleUsageSet.reset_column_information
    VehicleUsageSet.transaction do
      previous_times.each do |vehicle_usage_set_id, times|
        vehicle_usage_set = VehicleUsageSet.find(vehicle_usage_set_id)
        vehicle_usage_set.open = Time.at(times[:open]).utc.strftime('%H:%M:%S') if times[:open]
        vehicle_usage_set.close = Time.at(times[:close]).utc.strftime('%H:%M:%S') if times[:close]
        vehicle_usage_set.rest_start = Time.at(times[:rest_start]).utc.strftime('%H:%M:%S') if times[:rest_start]
        vehicle_usage_set.rest_stop = Time.at(times[:rest_stop]).utc.strftime('%H:%M:%S') if times[:rest_stop]
        vehicle_usage_set.rest_duration = Time.at(times[:rest_duration]).utc.strftime('%H:%M:%S') if times[:rest_duration]
        vehicle_usage_set.service_time_start = Time.at(times[:service_time_start]).utc.strftime('%H:%M:%S') if times[:service_time_start]
        vehicle_usage_set.service_time_end = Time.at(times[:service_time_end]).utc.strftime('%H:%M:%S') if times[:service_time_end]
        vehicle_usage_set.save!
      end
    end
  end
end
