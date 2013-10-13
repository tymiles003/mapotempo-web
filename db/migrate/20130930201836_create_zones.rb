class CreateZones < ActiveRecord::Migration
  def change
    create_table :zones do |t|
      t.text :polygon
      t.references :zoning, index: true

      t.timestamps
    end
  end
end
