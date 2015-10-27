class AlterCustomerOptimizationTime < ActiveRecord::Migration
  def up
    Customer.find_each{|customer|
      customer.optimization_time = customer.optimization_time / 1000
      customer.save!
    }
  end

  def down
    Customer.find_each{|customer|
      customer.optimization_time = customer.optimization_time * 1000
      customer.save!
    }
  end
end
