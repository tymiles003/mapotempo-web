class CreateStops < ActiveRecord::Migration
  def change
    create_table :stops do |t|
      t.integer :index
      t.boolean :active
      t.time :begin
      t.time :end
      t.float :distance
      t.text :trace
      t.references :route, index: true
      t.references :destination, index: true

      t.timestamps
    end
  end
end
