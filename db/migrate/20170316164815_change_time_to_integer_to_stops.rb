class ChangeTimeToIntegerToStops < ActiveRecord::Migration
  def up
    previous_times = {}
    Stop.all.order(:id).each do |stop|
      previous_times[stop.id] = {
          time: stop.time
      }
    end

    remove_column :stops, :time
    add_column :stops, :time, :integer

    Stop.reset_column_information
    Stop.transaction do
      previous_times.each do |stop_id, times|
        stop = Stop.find(stop_id)
        stop.time = times[:time].seconds_since_midnight.to_i if times[:time]
        stop.save!
      end
    end
  end

  def down
    previous_times = {}
    Stop.all.order(:id).each do |stop|
      previous_times[stop.id] = {
          time: stop.time
      }
    end

    remove_column :stops, :time
    add_column :stops, :time, :time

    Stop.reset_column_information
    Stop.transaction do
      previous_times.each do |stop_id, times|
        stop = Stop.find(stop_id)
        stop.time = Time.at(times[:time]).utc.strftime('%H:%M:%S') if times[:time]
        stop.save!
      end
    end
  end
end
