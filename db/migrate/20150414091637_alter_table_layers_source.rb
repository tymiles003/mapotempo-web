class AlterTableLayersSource < ActiveRecord::Migration
  def up
    add_column :layers, :source, :string

    Layer.all.each { |layer|
      layer.source = 'osm'
      layer.save!
    }

    change_column :layers, :source, :string, null: false
  end

  def down
    remove_column :layers, :source
  end
end
