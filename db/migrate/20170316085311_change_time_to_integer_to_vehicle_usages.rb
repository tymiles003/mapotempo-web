class ChangeTimeToIntegerToVehicleUsages < ActiveRecord::Migration
  def up
    previous_times = {}
    VehicleUsage.all.order(:id).each do |vehicle_usage|
      previous_times[vehicle_usage.id] = {
          open: vehicle_usage.open,
          close: vehicle_usage.close,
          rest_start: vehicle_usage.rest_start,
          rest_stop: vehicle_usage.rest_stop,
          rest_duration: vehicle_usage.rest_duration,
          service_time_start: vehicle_usage.service_time_start,
          service_time_end: vehicle_usage.service_time_end
      }
    end

    remove_column :vehicle_usages, :open
    remove_column :vehicle_usages, :close
    remove_column :vehicle_usages, :rest_start
    remove_column :vehicle_usages, :rest_stop
    remove_column :vehicle_usages, :rest_duration
    remove_column :vehicle_usages, :service_time_start
    remove_column :vehicle_usages, :service_time_end
    add_column :vehicle_usages, :open, :integer
    add_column :vehicle_usages, :close, :integer
    add_column :vehicle_usages, :rest_start, :integer
    add_column :vehicle_usages, :rest_stop, :integer
    add_column :vehicle_usages, :rest_duration, :integer
    add_column :vehicle_usages, :service_time_start, :integer
    add_column :vehicle_usages, :service_time_end, :integer

    VehicleUsage.reset_column_information
    VehicleUsage.transaction do
      previous_times.each do |vehicle_usage_id, times|
        vehicle_usage = VehicleUsage.find(vehicle_usage_id)
        vehicle_usage.open = times[:open].seconds_since_midnight.to_i if times[:open]
        vehicle_usage.close = times[:close].seconds_since_midnight.to_i if times[:close]
        vehicle_usage.rest_start = times[:rest_start].seconds_since_midnight.to_i if times[:rest_start]
        vehicle_usage.rest_stop = times[:rest_stop].seconds_since_midnight.to_i if times[:rest_stop]
        vehicle_usage.rest_duration = times[:rest_duration].seconds_since_midnight.to_i if times[:rest_duration]
        vehicle_usage.service_time_start = times[:service_time_start].seconds_since_midnight.to_i if times[:service_time_start]
        vehicle_usage.service_time_end = times[:service_time_end].seconds_since_midnight.to_i if times[:service_time_end]
        vehicle_usage.save!
      end
    end
  end

  def down
    previous_times = {}
    VehicleUsage.all.order(:id).each do |vehicle_usage|
      previous_times[vehicle_usage.id] = {
          open: vehicle_usage.open,
          close: vehicle_usage.close,
          rest_start: vehicle_usage.rest_start,
          rest_stop: vehicle_usage.rest_stop,
          rest_duration: vehicle_usage.rest_duration,
          service_time_start: vehicle_usage.service_time_start,
          service_time_end: vehicle_usage.service_time_end
      }
    end

    remove_column :vehicle_usages, :open
    remove_column :vehicle_usages, :close
    remove_column :vehicle_usages, :rest_start
    remove_column :vehicle_usages, :rest_stop
    remove_column :vehicle_usages, :rest_duration
    remove_column :vehicle_usages, :service_time_start
    remove_column :vehicle_usages, :service_time_end
    add_column :vehicle_usages, :open, :time
    add_column :vehicle_usages, :close, :time
    add_column :vehicle_usages, :rest_start, :time
    add_column :vehicle_usages, :rest_stop, :time
    add_column :vehicle_usages, :rest_duration, :time
    add_column :vehicle_usages, :service_time_start, :time
    add_column :vehicle_usages, :service_time_end, :time

    VehicleUsage.reset_column_information
    VehicleUsage.transaction do
      previous_times.each do |vehicle_usage_id, times|
        vehicle_usage = VehicleUsage.find(vehicle_usage_id)
        vehicle_usage.open = Time.at(times[:open]).utc.strftime('%H:%M:%S') if times[:open]
        vehicle_usage.close = Time.at(times[:close]).utc.strftime('%H:%M:%S') if times[:close]
        vehicle_usage.rest_start = Time.at(times[:rest_start]).utc.strftime('%H:%M:%S') if times[:rest_start]
        vehicle_usage.rest_stop = Time.at(times[:rest_stop]).utc.strftime('%H:%M:%S') if times[:rest_stop]
        vehicle_usage.rest_duration = Time.at(times[:rest_duration]).utc.strftime('%H:%M:%S') if times[:rest_duration]
        vehicle_usage.service_time_start = Time.at(times[:service_time_start]).utc.strftime('%H:%M:%S') if times[:service_time_start]
        vehicle_usage.service_time_end = Time.at(times[:service_time_end]).utc.strftime('%H:%M:%S') if times[:service_time_end]
        vehicle_usage.save!
      end
    end
  end
end
