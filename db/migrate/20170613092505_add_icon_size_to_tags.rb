class AddIconSizeToTags < ActiveRecord::Migration
  def change
    add_column :tags, :icon_size, :string
  end
end
