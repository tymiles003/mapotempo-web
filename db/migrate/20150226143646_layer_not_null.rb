class LayerNotNull < ActiveRecord::Migration
  def up
    change_column :layers, :name, :string, :null => false
    change_column :layers, :url, :string, :null => false
    change_column :layers, :attribution, :string, :null => false
    change_column :layers, :urlssl, :string, :null => false
  end

  def down
    change_column :layers, :name, :string
    change_column :layers, :url, :string
    change_column :layers, :attribution, :string
    change_column :layers, :urlssl, :string
  end
end
