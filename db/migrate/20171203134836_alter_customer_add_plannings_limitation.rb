class AlterCustomerAddPlanningsLimitation < ActiveRecord::Migration
  def up
    add_column :customers, :max_plannings, :integer
    add_column :customers, :max_zonings, :integer
    add_column :customers, :max_destinations, :integer
    add_column :customers, :max_vehicle_usage_sets, :integer

    Customer.find_each do |customer|
      customer.max_plannings = customer.plannings.size + 1 if customer.too_many_plannings?
      customer.max_zonings = customer.zonings.size + 1 if customer.too_many_zonings?
      customer.max_destinations = customer.destinations.size + 100 if customer.too_many_destinations?
      customer.max_vehicle_usage_sets = customer.vehicle_usage_sets.size + 1 if customer.too_many_vehicle_usage_sets? && customer.vehicle_usage_sets.size > 1
      customer.save!
    end
  end

  def down
    remove_column :customers, :max_plannings
    remove_column :customers, :max_zonings
    remove_column :customers, :max_destinations
    remove_column :customers, :max_vehicle_usage_sets
  end
end
