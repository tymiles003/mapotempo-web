module NoticoBase

  def add_notico_credentials(customer)
    customer.devices = {
        notico: {
            enable: 'true',
            username: 'login',
            password: 'password'
        }
    }
    customer.save!
    customer
  end

  def set_route
    @route = routes(:route_one_one)
    @vehicle = @route.vehicle_usage.vehicle
    @vehicle.update!(devices: {agentId: '110110-3'})
  end
end
