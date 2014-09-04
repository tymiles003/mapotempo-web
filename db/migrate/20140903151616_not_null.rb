class NotNull < ActiveRecord::Migration
  def up
    change_column :plannings, :customer_id, :integer, :null => false

    change_column :routes, :planning_id, :integer, :null => false

    change_column :stops, :route_id, :integer, :null => false
    change_column :stops, :destination_id, :integer, :null => false

    change_column :tags, :customer_id, :integer, :null => false

    change_column :users, :layer_id, :integer, :null => false

    change_column :vehicles, :customer_id, :integer, :null => false

    change_column :zones, :zoning_id, :integer, :null => false

    change_column :zonings, :customer_id, :integer, :null => false

    change_column :destinations_tags, :destination_id, :integer, :null => false
    change_column :destinations_tags, :tag_id, :integer, :null => false

    change_column :plannings_tags, :planning_id, :integer, :null => false
    change_column :plannings_tags, :tag_id, :integer, :null => false

    change_column :vehicles_zones, :vehicle_id, :integer, :null => false
    change_column :vehicles_zones, :zone_id, :integer, :null => false
  end

  def down
    change_column :plannings, :customer_id, :integer

    change_column :routes, :planning_id, :integer

    change_column :stops, :route_id, :integer
    change_column :stops, :destination_id, :integer

    change_column :tags, :customer_id, :integer

    change_column :users, :layer_id, :integer

    change_column :vehicles, :customer_id, :integer

    change_column :zones, :zoning_id, :integer

    change_column :zonings, :customer_id, :integer

    change_column :destinations_tags, :destination_id, :integer
    change_column :destinations_tags, :tag_id, :integer

    change_column :plannings_tags, :planning_id, :integer
    change_column :plannings_tags, :tag_id, :integer

    change_column :vehicles_zones, :vehicle_id, :integer
    change_column :vehicles_zones, :zone_id, :integer
  end
end
