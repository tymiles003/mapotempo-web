class AlterTablePlanningDate < ActiveRecord::Migration
  def up
    add_column :plannings, :date, :date

    Planning.where.not(order_array_shift: nil).each{ |planning|
      if planning.order_array
        planning.date = planning.order_array.base_date + planning.order_array_shift
      end
    }

    remove_column :plannings, :order_array_shift
  end

  def down
    add_column :plannings, :order_array_shift, :integer

    Planning.where.not(date: nil).each{ |planning|
      if planning.date && planning.order_array
        planning.order_array_shift = planning.date - planning.order_array.date
      end
    }

    remove_column :plannings, :date
  end
end
