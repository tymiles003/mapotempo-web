class AlterUserClick2callUrl < ActiveRecord::Migration
  def up
    add_column :users, :url_click2call, :string
  end

  def down
    remove_column :users, :url_click2call, :string
  end
end
