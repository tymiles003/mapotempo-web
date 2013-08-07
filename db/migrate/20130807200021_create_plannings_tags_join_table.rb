
class CreatePlanningsTagsJoinTable < ActiveRecord::Migration
  def change
    create_table :plannings_tags, id: false do |t|
      t.integer :planning_id
      t.integer :tag_id
    end
  end
end

