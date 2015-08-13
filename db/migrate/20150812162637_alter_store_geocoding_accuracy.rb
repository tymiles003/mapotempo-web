class AlterStoreGeocodingAccuracy < ActiveRecord::Migration
  def up
    add_column :stores, :geocoding_accuracy, :float
  end

  def down
    remove_column :stores, :geocoding_accuracy
  end
end
