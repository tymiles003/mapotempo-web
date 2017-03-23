class AddVehiclesDevices < ActiveRecord::Migration
  def up
    add_column :vehicles, :devices, :jsonb, default: {}, null: false

    Vehicle.order(:id).each{ |vehicle|
      vehicle.devices = {
        tomtom_id: vehicle.tomtom_id,
        orange_id: vehicle.orange_id,
        teksat_id: vehicle.teksat_id,
        masternaut_ref: vehicle.masternaut_ref,
        trimble_ref: nil,
        suiviDeFlotte_ref: nil,
        locster_ref: nil,
        alyacom_ref: nil
      }

      vehicle.save!
    }

    remove_column :vehicles, :tomtom_id
    remove_column :vehicles, :orange_id
    remove_column :vehicles, :teksat_id
    remove_column :vehicles, :masternaut_ref
  end

  def down
    add_column :vehicles, :tomtom_id, :string
    add_column :vehicles, :orange_id, :string
    add_column :vehicles, :teksat_id, :string
    add_column :vehicles, :masternaut_ref, :string

    Vehicle.order(:id).each{ |vehicle|
      json = vehicle.devices || {}
      vehicle.tomtom_id = json[:tomtom_id]
      vehicle.orange_id = json[:orange_id]
      vehicle.teksat_id = json[:teksat_id]
      vehicle.masternaut_ref = json[:masternaut_ref]

      vehicle.save!
    }

    remove_column :vehicles, :devices
  end
end
