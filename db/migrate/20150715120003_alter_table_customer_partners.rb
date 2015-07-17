class AlterTableCustomerPartners < ActiveRecord::Migration
  def up
    add_column :customers, :enable_tomtom, :boolean, default: true, null: false
    add_column :customers, :enable_masternaut, :boolean, default: true, null: false
    add_column :customers, :enable_alyacom, :boolean, default: true, null: false
    change_column_default(:customers, :enable_tomtom, false)
    change_column_default(:customers, :enable_masternaut, false)
    change_column_default(:customers, :enable_alyacom, false)
  end

  def down
    remove_column :customers, :enable_tomtom
    remove_column :customers, :enable_masternaut
    remove_column :customers, :enable_alyacom
  end
end
