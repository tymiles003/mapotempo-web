class AddRefToDeliverableUnit < ActiveRecord::Migration
  def change
    add_column  :deliverable_units, :ref, :string

    add_index   :deliverable_units, [:customer_id, :ref], unique: true
  end
end
