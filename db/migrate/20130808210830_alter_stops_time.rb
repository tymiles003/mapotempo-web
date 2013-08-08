class AlterStopsTime < ActiveRecord::Migration
  def change
    add_column :stops, :time, :time
  end
end
