class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.float :distance
      t.float :emission
      t.references :planning, index: true
      t.boolean :out_of_date
      t.references :vehicle, index: true

      t.timestamps
    end
  end
end
