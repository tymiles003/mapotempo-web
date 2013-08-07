class CreateLayers < ActiveRecord::Migration
  def change
    create_table :layers do |t|
      t.string :name
      t.string :url
      t.string :attribution

      t.timestamps
    end
  end
end
