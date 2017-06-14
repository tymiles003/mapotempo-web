class AddLocaleToLayers < ActiveRecord::Migration
  def change
    add_column :layers, :name_locale, :hstore, default: {}, null: false
  end
end
