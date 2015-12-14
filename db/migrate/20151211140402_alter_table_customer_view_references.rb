class AlterTableCustomerViewReferences < ActiveRecord::Migration
  def up
    add_column :customers, :enable_references, :boolean, default: true
  end
  def down
    remove_column :customers, :enable_references
  end
end
