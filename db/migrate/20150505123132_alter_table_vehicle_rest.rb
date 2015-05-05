class AlterTableVehicleRest < ActiveRecord::Migration
  def up
    add_column :vehicles, :rest_start, :time
    add_column :vehicles, :rest_stop, :time
    add_column :vehicles, :rest_duration, :time
    add_column :vehicles, :store_rest_id, :integer

    add_foreign_key :vehicles, :stores, column: :store_rest_id
  end

  def down
    remove_foreign_key :vehicles, column: :store_rest_id

    remove_column :vehicles, :rest_start
    remove_column :vehicles, :rest_stop
    remove_column :vehicles, :rest_duration
    remove_column :vehicles, :store_rest_id
  end
end
