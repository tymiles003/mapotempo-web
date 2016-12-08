class AddPreferedUnityToUser < ActiveRecord::Migration
  def change
    add_column :users, :prefered_unity, :string
  end
end
