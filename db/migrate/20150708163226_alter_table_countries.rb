class AlterTableCountries < ActiveRecord::Migration
  def up
    add_column :customers, :default_country, :string, default: 'France', null: false
    change_column_default(:customers, :default_country, nil)
    add_column :stores, :country, :string
    add_column :destinations, :country, :string
  end

  def down
    remove_column :customers, :default_country
    remove_column :stores, :country
    remove_column :destinations, :country
  end
end
