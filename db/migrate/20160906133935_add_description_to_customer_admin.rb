class AddDescriptionToCustomerAdmin < ActiveRecord::Migration
  def up
    add_column :customers, :description, :string
  end

  def down
    remove_column :customers, :description
  end
end
