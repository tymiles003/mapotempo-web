class AlterTableLayerAddOverlay < ActiveRecord::Migration
  def up
    add_column :layers, :overlay, :boolean, default: false
  end
  def down
    remove_column :layers, :overlay
  end
end
