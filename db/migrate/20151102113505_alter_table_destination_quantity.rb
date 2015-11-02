class AlterTableDestinationQuantity < ActiveRecord::Migration
  def up
    change_column :destinations, :quantity, :float
  end
  def down
    change_column :destinations, :quantity, :integer
  end
end
