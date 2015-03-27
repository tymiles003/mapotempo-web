class V01::Vehicles < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def vehicle_params
      p = ActionController::Parameters.new(params)
      p = p[:vehicle] if p.key?(:vehicle)
      p.permit(:name, :emission, :consumption, :capacity, :color, :open, :close, :tomtom_id, :store_start_id, :store_stop_id, :router_id)
    end
  end

  resource :vehicles do
    desc 'Fetch customer\'s vehicles.', {
      nickname: 'getVehicles'
    }
    get do
      present current_customer.vehicles.load, with: V01::Entities::Vehicle
    end

    desc 'Fetch vehicle.', {
      nickname: 'getVehicle'
    }
    params {
      requires :id, type: Integer
    }
    get ':id' do
      present current_customer.vehicles.find(params[:id]), with: V01::Entities::Vehicle
    end

    desc 'Update vehicle.', {
      nickname: 'updateVehicle',
      params: V01::Entities::Vehicle.documentation.except(:id)
    }
    params {
      requires :id, type: Integer
    }
    put ':id' do
      vehicle = current_customer.vehicles.find(params[:id])
      vehicle.update(vehicle_params)
      vehicle.save!
      present vehicle, with: V01::Entities::Vehicle
    end
  end
end
