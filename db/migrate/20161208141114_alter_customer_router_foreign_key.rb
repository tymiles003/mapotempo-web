class AlterCustomerRouterForeignKey < ActiveRecord::Migration
  def change
    add_foreign_key :customers, :routers
  end
end
