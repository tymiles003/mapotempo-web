class AlterTableTagsColorIcon < ActiveRecord::Migration
  def up
    add_column :tags, :color, :string
    add_column :tags, :icon, :string
  end

  def down
    remove_column :tags, :color
    remove_column :tags, :icon
  end
end
