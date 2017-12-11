class AlterCustomerRemoveEnableMultiVehicleUsageSets < ActiveRecord::Migration
  def up
    Customer.find_each do |customer|
      # Customers with more than 1 vehicle_usage_sets have been already migrated in AlterCustomerAddPlanningsLimitation
      customer.max_vehicle_usage_sets = 2 if customer.enable_multi_vehicle_usage_sets && customer.vehicle_usage_sets.size == 1
      customer.save!
    end

    remove_column :customers, :enable_multi_vehicle_usage_sets
  end

  def down
    add_column :customers, :enable_multi_vehicle_usage_sets, :boolean, default: true, null: false

    Customer.find_each do |customer|
      customer.enable_multi_vehicle_usage_sets = true if customer.default_max_vehicle_usage_sets > 1
      customer.save!
    end
  end
end
