class AlterTableCustomerMaxVehicles < ActiveRecord::Migration
  def up
    Customer.all.each { |c|
      c.max_vehicles = c.vehicles.count
      c.save!
    }
    change_column :customers, :max_vehicles, :integer, null: false
  end

  def down
    change_column :customers, :max_vehicles, :integer, null: true
  end
end
