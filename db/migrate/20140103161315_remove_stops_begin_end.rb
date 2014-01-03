class RemoveStopsBeginEnd < ActiveRecord::Migration
  def change
    remove_column :stops, :begin
    remove_column :stops, :end
  end
end
