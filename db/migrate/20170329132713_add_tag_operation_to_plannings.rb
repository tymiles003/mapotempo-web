class AddTagOperationToPlannings < ActiveRecord::Migration
  def change
    add_column :plannings, :tag_operation, :integer, null: false, default: 0
  end
end
