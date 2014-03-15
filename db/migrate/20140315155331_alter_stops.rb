class AlterStops < ActiveRecord::Migration
  def down
    change_column :stops, :time, :time
    change_column :routes, :start, :time
    change_column :routes, :end, :time
  end

  def up
    change_column :stops, :time, :datetime
    change_column :routes, :start, :datetime
    change_column :routes, :end, :datetime
  end
end
