class AlterTableVehicleDefaultValues < ActiveRecord::Migration
  def up
    Customer.all.each{ |customer|
      customer.vehicles.each{ |vehicle|
        vehicle.emission = nil if vehicle.emission == 0
        vehicle.consumption = nil if vehicle.consumption == 0
        vehicle.capacity = nil if vehicle.capacity == 999
      }
      customer.save!
    }
  end
  def down
    Customer.all.each{ |customer|
      customer.vehicles.each{ |vehicle|
        vehicle.emission = 0 if vehicle.emission.nil?
        vehicle.consumption = 0 if vehicle.consumption.nil?
        vehicle.capacity = 999 if vehicle.capacity.nil?
      }
      customer.save!
    }
  end
end
