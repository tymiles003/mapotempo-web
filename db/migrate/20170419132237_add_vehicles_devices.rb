class AddVehiclesDevices < ActiveRecord::Migration
  def up
    Vehicle.connection.schema_cache.clear!
    Vehicle.reset_column_information

    remove_devices_store_accessor

    add_column :vehicles, :devices, :jsonb, default: {}, null: false

    Vehicle.order(:id).each{ |vehicle|
      vehicle.devices = {
        tomtom_id: vehicle.tomtom_id,
        orange_id: vehicle.orange_id,
        teksat_id: vehicle.teksat_id,
        masternaut_ref: vehicle.masternaut_ref,
        trimble_ref: nil,
        suivi_de_flotte_id: nil,
        locster_ref: nil
      }

      vehicle.save!
    }

    raise 'Incorrect devices migration' if Vehicle.all.map(&:devices).uniq.first == {} && (Vehicle.all.map(&:tomtom_id).compact.size > 0 || Vehicle.all.map(&:orange_id).compact.size > 0 || Vehicle.all.map(&:teksat_id).compact.size > 0 || Vehicle.all.map(&:masternaut_ref).compact.size > 0)

    remove_column :vehicles, :tomtom_id
    remove_column :vehicles, :orange_id
    remove_column :vehicles, :teksat_id
    remove_column :vehicles, :masternaut_ref
  end

  def down
    Vehicle.connection.schema_cache.clear!
    Vehicle.reset_column_information

    remove_devices_store_accessor

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

  def remove_devices_store_accessor
    Vehicle.class_eval do
      remove_method :tomtom_id
      remove_method :orange_id
      remove_method :teksat_id
      remove_method :masternaut_ref
    end
  end
end
