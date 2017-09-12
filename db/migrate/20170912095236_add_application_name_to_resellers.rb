class AddApplicationNameToResellers < ActiveRecord::Migration
  def change
    add_column :resellers, :application_name, :string
  end
end
