class AlterTableDeleteCascade < ActiveRecord::Migration
  def change
    change_column :destinations, :customer_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :tags, :customer_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :destinations_tags, :destination_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }
    change_column :destinations_tags, :tag_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :order_arrays, :customer_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :orders, :order_array_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }
    change_column :orders, :destination_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :products, :customer_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :orders_products, :order_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }
    change_column :orders_products, :product_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :zonings, :customer_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :plannings, :customer_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :plannings_tags, :planning_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }
    change_column :plannings_tags, :tag_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :stores, :customer_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :vehicles, :customer_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :routes, :planning_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }
    change_column :routes, :vehicle_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :stops, :destination_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }
    change_column :stops, :route_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :stores_vehicules, :store_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }
    change_column :stores_vehicules, :vehicle_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }

    change_column :zones, :zoning_id, :integer, foreign_key: { deferrable: true, on_delete: :cascade }
  end
end
