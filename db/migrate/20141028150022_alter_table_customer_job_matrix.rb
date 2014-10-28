class AlterTableCustomerJobMatrix < ActiveRecord::Migration
  def up
    remove_column :customers, :job_matrix_id
  end

  def down
    add_column :customers, :job_matrix_id, :integer
  end

end
