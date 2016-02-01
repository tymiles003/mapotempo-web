class AlterTableCustomerAddEnableMultiVisits < ActiveRecord::Migration
  def up
    add_column :customers, :enable_multi_visits, :boolean, default: false, null: false
  end

  def down
    remove_column :customers, :enable_multi_visits
  end
end
