class CreateDestinations < ActiveRecord::Migration
  def change
    create_table :destinations do |t|
      t.string :name
      t.string :street
      t.string :postalcode
      t.string :city
      t.float :lat
      t.float :lng
      t.integer :quantity
      t.time :open
      t.time :close
      t.references :customer, index: true

      t.timestamps
    end
  end
end
