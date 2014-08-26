class Foreignkey < ActiveRecord::Migration
  def up
    change_column :destinations, :customer_id, :integer, foreign_key: { deferrable: true }

    change_column :plannings, :customer_id, :integer, foreign_key: { deferrable: true }
    change_column :plannings, :zoning_id, :integer, foreign_key: { deferrable: true }

    change_column :routes, :planning_id, :integer, foreign_key: { deferrable: true }
    change_column :routes, :vehicle_id, :integer, foreign_key: { deferrable: true }

    change_column :stops, :route_id, :integer, foreign_key: { deferrable: true }
    change_column :stops, :destination_id, :integer, foreign_key: { deferrable: true }

    change_column :tags, :customer_id, :integer, foreign_key: { deferrable: true }

    change_column :users, :customer_id, :integer, foreign_key: { deferrable: true }
    change_column :users, :layer_id, :integer, foreign_key: { deferrable: true }

    change_column :vehicles, :customer_id, :integer, foreign_key: { deferrable: true }

    change_column :zones, :zoning_id, :integer, foreign_key: { deferrable: true }

    change_column :zonings, :customer_id, :integer, foreign_key: { deferrable: true }

    change_column :destinations_tags, :destination_id, :integer, foreign_key: { deferrable: true }
    change_column :destinations_tags, :tag_id, :integer, foreign_key: { deferrable: true }

    change_column :plannings_tags, :planning_id, :integer, foreign_key: { deferrable: true }
    change_column :plannings_tags, :tag_id, :integer, foreign_key: { deferrable: true }

    change_column :vehicles_zones, :vehicle_id, :integer, foreign_key: { deferrable: true }
    change_column :vehicles_zones, :zone_id, :integer, foreign_key: { deferrable: true }
  end

  def down
    change_column :destinations, :customer_id, :integer

    change_column :plannings, :customer_id, :integer
    change_column :plannings, :zoning_id, :integer

    change_column :routes, :planning_id, :integer
    change_column :routes, :vehicle_id, :integer

    change_column :stops, :route_id, :integer
    change_column :stops, :destination_id, :integer

    change_column :tags, :customer_id, :integer

    change_column :users, :customer_id, :integer
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
