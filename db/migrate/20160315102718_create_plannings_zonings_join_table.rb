class CreatePlanningsZoningsJoinTable < ActiveRecord::Migration
  def up
    fake_missing_props

    create_table :plannings_zonings, id: false do |t|
      t.integer :planning_id
      t.integer :zoning_id
    end

    Planning.find_each{ |planning|
      if planning.zoning
        planning.zonings << planning.zoning
        planning.save
      end
    }

    add_foreign_key :plannings_zonings, :plannings, on_delete: :cascade
    add_index :plannings_zonings, :planning_id
    add_foreign_key :plannings_zonings, :zonings, on_delete: :cascade
    add_index :plannings_zonings, :zoning_id

    remove_columns :plannings, :zoning_id
  end

  def down
    fake_missing_props

    add_column :plannings, :zoning_id, :integer

    add_foreign_key :plannings, :zonings, on_delete: :cascade
    add_index :plannings, :zoning_id

    Planning.find_each{ |planning|
      if planning.zonings.size > 0
        planning.zoning = planning.zonings.first
        planning.save
      end
    }

    drop_table :plannings_zonings
  end

  private

  def fake_missing_props
    Planning.class_eval do
      belongs_to :zoning
    end
  end
end
