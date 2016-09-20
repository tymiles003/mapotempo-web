class CreateTableDeliverableUnit < ActiveRecord::Migration
  def up
    create_table :deliverable_units do |t|
      t.references :customer, index: true
      t.string :label
      t.float :default_quantity
      t.float :default_capacity
      t.float :optimization_overload_multiplier
    end

    enable_extension 'hstore'

    add_column :visits, :quantities, :hstore

    add_column :vehicles, :capacities, :hstore

    any_capacities = any_quantities = nil
    Customer.order(:id).each{ |customer|
      # Get deliverable units from first vehicle with any capacity
      v = customer.vehicles.find{ |v| v.capacity1_1 || v.capacity1_1_unit || v.capacity1_2 || v.capacity1_2_unit } || customer.vehicles[0]
      # First deliverable unit always created
      [v.capacity1_1_unit || '', v.capacity1_2_unit || (v.capacity1_2 ? '' : nil)].compact.each_with_index{ |unit, index|
        customer.deliverable_units.build label: unit, default_quantity: index.zero? ? 1 : nil, optimization_overload_multiplier: 0.1
      }
      if customer.deliverable_units.size > 0
        def customer.update_out_of_date; end
        customer.save!
        customer.vehicles.each{ |vehicle|
          def vehicle.update_out_of_date; end
          any_capacities ||= vehicle.capacity1_1? || vehicle.capacity1_2?
          vehicle.capacities[customer.deliverable_units[0].id] = vehicle.capacity1_1 if vehicle.capacity1_1 && customer.deliverable_units[0]
          vehicle.capacities[customer.deliverable_units[1].id] = vehicle.capacity1_2 if vehicle.capacity1_2 && customer.deliverable_units[1]
          vehicle.save!
        }
        customer.destinations.flat_map{ |dest|
          dest.visits
        }.each{ |visit|
          def visit.update_out_of_date; end
          any_quantities ||= visit.quantity1_1? || visit.quantity1_2?
          visit.quantities[customer.deliverable_units[0].id] = visit.quantity1_1 if visit.quantity1_1 && customer.deliverable_units[0]
          visit.quantities[customer.deliverable_units[1].id] = visit.quantity1_2 if visit.quantity1_2 && customer.deliverable_units[1]
          visit.save!
        }
      end
    }
    raise 'Incorrect migration' if (any_capacities && Vehicle.all.all?{ |v| v.capacities.all?{ |q| !q } }) || (any_quantities && Visit.all.all?{ |v| v.quantities.all?{ |q| !q } })

    remove_column :vehicles, :capacity1_1
    remove_column :vehicles, :capacity1_1_unit
    remove_column :vehicles, :capacity1_2
    remove_column :vehicles, :capacity1_2_unit

    remove_column :visits, :quantity1_1
    remove_column :visits, :quantity1_2
  end

  def down

    add_column :vehicles, :capacity1_1, :integer
    add_column :vehicles, :capacity1_1_unit, :string
    add_column :vehicles, :capacity1_2, :integer
    add_column :vehicles, :capacity1_2_unit, :string

    add_column :visits, :quantity1_1, :float
    add_column :visits, :quantity1_2, :float

    any_capacities = any_quantities = nil
    Customer.find_each{ |customer|
      if customer.deliverable_units.size > 0
        customer.vehicles.each{ |v|
          def v.capacities_changed?; end
          any_capacities ||= v.capacities.any?{ |c| !c }
          v.capacity1_1_unit = customer.deliverable_units[0].label if customer.deliverable_units[0].try(&:label)
          v.capacity1_2_unit = customer.deliverable_units[1].label if customer.deliverable_units[1].try(&:label)
          v.capacity1_1 = v.capacities[customer.deliverable_units[0].id] if v.capacities && customer.deliverable_units[0]
          v.capacity1_2 = v.capacities[customer.deliverable_units[1].id] if v.capacities && customer.deliverable_units[1]
          v.save!
        }
        customer.destinations.flat_map{ |dest|
          dest.visits
        }.each{ |visit|
          def visit.quantities_changed?; end
          any_quantities ||= visit.quantities.any?{ |q| !q }
          visit.quantity1_1 = visit.quantities[customer.deliverable_units[0].id] if visit.quantities && customer.deliverable_units[0]
          visit.quantity1_2 = visit.quantities[customer.deliverable_units[1].id] if visit.quantities && customer.deliverable_units[1]
          visit.save!
        }
      end
    }
    raise 'Incorrect migration' if (any_capacities && Vehicle.all.all?{ |v| !v.capacity1_1 && !v.capacity1_2 }) || (any_quantities && Visit.all.all?{ |v| !v.quantity1_1 && !v.quantity1_2 })

    remove_column :vehicles, :capacities

    remove_column :visits, :quantities

    drop_table :deliverable_units
  end
end
