class AddBeginAndEndDateToPlannings < ActiveRecord::Migration
  def change
    add_column :plannings, :begin_date, :date
    add_column :plannings, :end_date, :date
  end
end
