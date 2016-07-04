class AlterRouteOptimum < ActiveRecord::Migration
  def change
    add_column :routes, :optimized_at, :datetime, null: true, default: nil
  end
end
