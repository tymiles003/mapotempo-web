class ChangeTimeToIntegerToStops < ActiveRecord::Migration
  def up
    fake_missing_props

    add_column :stops, :time_temp, :integer

    Stop.connection.schema_cache.clear!
    Stop.reset_column_information

    Stop.find_in_batches do |stops|
      stops.each do |stop|
        stop.time_temp = stop.time.seconds_since_midnight.to_i if stop.time
        stop.save!
      end
    end

    remove_column :stops, :time

    rename_column :stops, :time_temp, :time
  end

  def down
    add_column :stops, :time_temp, :time

    Stop.connection.schema_cache.clear!
    Stop.reset_column_information

    Stop.find_in_batches do |stops|
      stops.each do |stop|
        stop.time_temp = Time.at(stop.time).utc.strftime('%H:%M:%S') if stop.time
        stop.save!
      end
    end

    fake_missing_props

    remove_column :stops, :time

    rename_column :stops, :time_temp, :time
  end

  def fake_missing_props
    Stop.class_eval do
      attribute :time, ActiveRecord::Type::Time.new
    end
  end
end
