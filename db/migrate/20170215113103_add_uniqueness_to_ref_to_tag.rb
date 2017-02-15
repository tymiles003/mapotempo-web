class AddUniquenessToRefToTag < ActiveRecord::Migration
  def change
    add_index :tags, [:customer_id, :ref], unique: true
  end
end
