class AlterTableCustomerAlyacomApiKey < ActiveRecord::Migration
  def up
    Customer.find_each{ |customer|
      if customer.devices[:alyacom] && customer.devices[:alyacom][:api_key]
        customer.devices[:alyacom][:alyacom_api_key] = customer.devices[:alyacom].delete(:api_key)
        customer.save!
      end
    }
  end
  def down
    Customer.find_each{ |customer|
      if customer.devices[:alyacom] && customer.devices[:alyacom][:alyacom_api_key]
        customer.devices[:alyacom][:api_key] = customer.devices[:alyacom].delete(:alyacom_api_key)
        customer.save!
      end
    }
  end
end
