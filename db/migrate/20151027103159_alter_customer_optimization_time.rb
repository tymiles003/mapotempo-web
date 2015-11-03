class AlterCustomerOptimizationTime < ActiveRecord::Migration
  def up
    Customer.find_each{|customer|
      if !customer.optimization_time.nil?
        customer.optimization_time /= 1000
        customer.save!
      end
    }
  end

  def down
    Customer.find_each{|customer|
      if !customer.optimization_time.nil?
        customer.optimization_time *= 1000
        customer.save!
      end
    }
  end
end
