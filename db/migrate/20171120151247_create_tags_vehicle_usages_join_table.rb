class CreateTagsVehicleUsagesJoinTable < ActiveRecord::Migration
  def change
    create_table :tags_vehicle_usages, id: false do |t|
      t.integer :vehicle_usage_id
      t.integer :tag_id
    end
  end
end
