class AlterDestinationGeocodingAccuracy < ActiveRecord::Migration
  def up
    add_column :destinations, :geocoding_accuracy, :float
  end

  def down
    remove_column :destinations, :geocoding_accuracy
  end
end
