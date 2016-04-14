class AlterTableLayerAddPrint < ActiveRecord::Migration
  def change
    add_column :layers, :print, :boolean, null: false, default: false
  end
end
