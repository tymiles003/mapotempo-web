class AddRouteAverages < ActiveRecord::Migration
  def up
    [:visits_duration, :wait_time, :drive_time].each do |name|
      add_column :routes, name, :integer, null: true
    end
  end

  def down
    [:visits_duration, :wait_time, :drive_time].each do |name|
      remove_column :routes, name
    end
  end
end
