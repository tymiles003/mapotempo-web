class AlterVehicleRouter < ActiveRecord::Migration
  def up
    add_column :vehicles, :router_id, :integer, references: :routers, foreign_key: { deferrable: true }
  end

  def down
    remove_column :vehicles, :router_id
  end
end
