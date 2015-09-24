class AlterTableCustomerMaxVehicles < ActiveRecord::Migration
  def up
    Customer.all.each { |c|
      c.max_vehicles = c.vehicles.count
      begin
        c.save!
      rescue => e
        puts 'Exception during migration: ' + e.message
      end
    }
    change_column :customers, :max_vehicles, :integer, null: false
  end

  def down
    change_column :customers, :max_vehicles, :integer, null: true
  end
end
