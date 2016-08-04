class AddPartNumberTotags < ActiveRecord::Migration
  def change
    add_column :tags, :ref, :string
  end
end
