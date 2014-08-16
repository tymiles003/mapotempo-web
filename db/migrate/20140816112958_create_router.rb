class CreateRouter < ActiveRecord::Migration
  def change
    create_table :routers do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
  end
end
