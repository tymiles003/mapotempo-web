
class CreateDestinationsTagsJoinTable < ActiveRecord::Migration
  def change
    create_table :destinations_tags, id: false do |t|
      t.integer :destination_id
      t.integer :tag_id
    end
  end
end

