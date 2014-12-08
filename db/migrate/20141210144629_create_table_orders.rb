class CreateTableOrders < ActiveRecord::Migration
  def up
    add_column :customers, :enable_orders, :boolean, default: false, null: false

    create_table :order_arrays do |t|
      t.string :name, null: false
      t.date :base_date, null: false
      t.integer :length, null: false
      t.references :customer, index: true, foreign_key: { deferrable: true }, null: false

      t.timestamps
    end

    create_table :orders do |t|
      t.integer :shift, null: false
      t.references :destination, index: true, foreign_key: { deferrable: true }, null: false
      t.references :order_array, index: true, foreign_key: { deferrable: true }, null: false

      t.timestamps
    end

    create_table :products do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.references :customer, index: true, foreign_key: { deferrable: true }, null: false

      t.timestamps
    end

    create_table :orders_products, id: false do |t|
      t.references :order, foreign_key: { deferrable: true }, null: false
      t.references :product, foreign_key: { deferrable: true }, null: false
    end
  end

  def down
    remove_column :customers, :enable_orders
    drop_table :orders_products
    drop_table :products
    drop_table :orders
    drop_table :order_arrays
  end
end
