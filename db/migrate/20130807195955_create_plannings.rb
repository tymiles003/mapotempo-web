class CreatePlannings < ActiveRecord::Migration
  def change
    create_table :plannings do |t|
      t.string :name
      t.references :customer, index: true

      t.timestamps
    end
  end
end
