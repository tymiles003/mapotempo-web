class AlterTableStopAddTimeInterval < ActiveRecord::Migration
  def up
    add_column :stops, :drive_time, :integer
    add_column :routes, :stop_drive_time, :integer
  end
  def down
    remove_column :stops, :drive_time
    remove_column :routes, :stop_drive_time
  end
end
