class AlterTableCustomerOrangeUser < ActiveRecord::Migration
  def up
    Customer.find_each{ |customer|
      if customer.devices[:orange] && customer.devices[:orange][:username]
        customer.devices[:orange][:user] = customer.devices[:orange].delete(:username)
        customer.save!
      end
    }
  end
  def down
    Customer.find_each{ |customer|
      if customer.devices[:orange] && customer.devices[:orange][:user]
        customer.devices[:orange][:username] = customer.devices[:orange].delete(:user)
        customer.save!
      end
    }
  end
end
