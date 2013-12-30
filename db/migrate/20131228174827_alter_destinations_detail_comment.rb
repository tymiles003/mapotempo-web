class AlterDestinationsDetailComment < ActiveRecord::Migration
  def change
    add_column :destinations, :detail, :string
    add_column :destinations, :comment, :string
  end
end
