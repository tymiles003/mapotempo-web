class CreateZonings < ActiveRecord::Migration
  def change
    create_table :zonings do |t|
      t.string :name
      t.references :customer, index: true

      t.timestamps
    end
  end
end
