class AlterOutOfDateToOutdated < ActiveRecord::Migration
  def change
    rename_column :routes, :out_of_date, :outdated
    rename_column :plannings, :zoning_out_of_date, :zoning_outdated
  end
end
