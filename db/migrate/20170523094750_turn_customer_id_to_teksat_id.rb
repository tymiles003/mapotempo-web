class TurnCustomerIdToTeksatId < ActiveRecord::Migration
  def up
    Customer.find_each{ |customer|
      if customer.devices[:teksat] && customer.devices[:teksat][:customer_id]
        customer.devices[:teksat][:teksat_customer_id] = customer.devices[:teksat].delete(:customer_id)
        customer.save!
      end
    }
  end

  def down
    Customer.find_each{ |customer|
      if customer.devices[:teksat] && customer.devices[:teksat][:teksat_customer_id]
        customer.devices[:teksat][:customer_id] = customer.devices[:teksat].delete(:teksat_customer_id)
        customer.save!
      end
    }
  end
end
