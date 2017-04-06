class AddStateToDestinations < ActiveRecord::Migration
  def change
    add_column :destinations, :state, :string
  end
end
