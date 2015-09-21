class AlterTableDestinationGeocodingLevel < ActiveRecord::Migration
  def up
    add_column :destinations, :geocoding_level, :integer
    add_column :stores, :geocoding_level, :integer
  end

  def down
    remove_column :destinations, :geocoding_level
    remove_column :stores, :geocoding_level
  end
end
