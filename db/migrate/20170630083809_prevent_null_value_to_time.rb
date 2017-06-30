class PreventNullValueToTime < ActiveRecord::Migration
  def up
    # Update current value to prevent null
    VehicleUsageSet.transaction do
      VehicleUsageSet.find_in_batches do |vehicle_usage_sets|
        vehicle_usage_sets.each do |vehicle_usage_set|
          vehicle_usage_set.open = 0 unless vehicle_usage_set.open
          vehicle_usage_set.close = 0 unless vehicle_usage_set.close
          vehicle_usage_set.save!(validate: false)
        end
      end
    end

    change_column_null :vehicle_usage_sets, :open, false
    change_column_null :vehicle_usage_sets, :close, false
  end

  def down
    change_column_null :vehicle_usage_sets, :open, true
    change_column_null :vehicle_usage_sets, :close, true
  end
end
