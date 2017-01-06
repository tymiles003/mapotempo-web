class AlterCustomerEnableLiveStatus < ActiveRecord::Migration
  def change
    add_column :customers, :enable_vehicle_position, :boolean, null: false, default: true
    add_column :customers, :enable_stop_status, :boolean, null: false, default: false
  end
end
