class AlterTableCustomerPartners < ActiveRecord::Migration
  def up
    add_column :customers, :enable_tomtom, :boolean, default: false, null: false
    add_column :customers, :enable_masternaut, :boolean, default: false, null: false
    add_column :customers, :enable_alyacom, :boolean, default: false, null: false
  end

  def down
    remove_column :customers, :enable_tomtom
    remove_column :customers, :enable_masternaut
    remove_column :customers, :enable_alyacom
  end
end
