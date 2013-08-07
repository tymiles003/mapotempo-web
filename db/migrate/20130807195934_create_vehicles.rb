class CreateVehicles < ActiveRecord::Migration
  def change
    create_table :vehicles do |t|
      t.string :name
      t.float :emission
      t.float :consumption
      t.integer :capacity
      t.string :color
      t.time :open
      t.time :close
      t.references :user, index: true

      t.timestamps
    end
  end
end
