class AlterLayersUrlssl < ActiveRecord::Migration
  def change
    add_column :layers, :urlssl, :string
  end
end
