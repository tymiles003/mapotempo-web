class AlterCustomerRouter < ActiveRecord::Migration
  def up
    add_column :customers, :router_id, :integer, references: :routers
    osrm = Router.create!(name: "project-osrm.org", url:"http://router.project-osrm.org")
    Customer.find_each{ |customer|
      customer.router = osrm
      customer.save!
    }
  end

  def down
    remove_column :customers, :router_id
  end
end
