class AlterStopsOutOf < ActiveRecord::Migration
  def change
    add_column :stops, :out_of_window, :boolean
    add_column :stops, :out_of_capacity, :boolean
    add_column :stops, :out_of_drive_time, :boolean
  end
end
