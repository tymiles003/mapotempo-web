class CreateTagsVehiclesJoinTable < ActiveRecord::Migration
  def change
    create_table :tags_vehicles, id: false do |t|
      t.integer :vehicle_id
      t.integer :tag_id
    end
  end
end
