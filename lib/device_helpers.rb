module Devices
  module Helpers

    def device_send_route options={}
      route = Route.for_customer(@customer).find params[:route_id]
      service.send_route options.merge(route: route)
      present route, with: V01::Entities::DeviceRouteLastSentAt
    end

    def device_send_routes options={}
      planning = @customer.plannings.find params[:planning_id]
      routes = planning.routes.select(&:vehicle_usage)
      routes = routes.select{|route| route.vehicle_usage.vehicle.send(options[:device_id]) } if options[:device_id]
      routes.each{|route| service.send_route options.merge(route: route) }
      present routes, with: V01::Entities::DeviceRouteLastSentAt
    end

    def device_clear_route options={}
      route = Route.for_customer(@customer).find params[:route_id]
      service.clear_route options.merge(route: route)
      present route, with: V01::Entities::DeviceRouteLastSentAt
    end

    def device_clear_routes options={}
      planning = @customer.plannings.find params[:planning_id]
      routes = planning.routes.select(&:vehicle_usage)
      routes = routes.select{|route| route.vehicle_usage.vehicle.send(options[:device_id]) } if options[:device_id]
      routes.each{|route| service.clear_route options.merge(route: route) }
      present routes, with: V01::Entities::DeviceRouteLastSentAt
    end

    def orange_fleet_authenticate customer
      user     = params[:orange_user]     ? params[:orange_user]      : customer.try(:orange_user)
      passwd   = params[:orange_password] ? params[:orange_password]  : customer.try(:orange_password)
      OrangeService.new(customer: customer).test_list(user: user, password: passwd)
    end

    def orange_sync_vehicles customer
      orange_vehicles = OrangeService.new(customer: customer).list_devices
      vehicles = customer.vehicles.take [orange_vehicles.length, customer.vehicles.count].min
      vehicles.each_with_index{|vehicle, index| vehicle.update!(orange_id: orange_vehicles[index][:id]) }
    end

    def teksat_authenticate customer
      url      = params[:teksat_url]         ? params[:teksat_url]         : customer.try(:teksat_url)
      cust_id  = params[:teksat_customer_id] ? params[:teksat_customer_id] : customer.try(:teksat_customer_id)
      username = params[:teksat_username]    ? params[:teksat_username]    : customer.try(:teksat_username)
      password = params[:teksat_password]    ? params[:teksat_password]    : customer.try(:teksat_password)
      if params[:check_only].to_i == 1 || !session[:teksat_ticket_id] || (Time.now - Time.at(session[:teksat_authenticated_at])) > 3.hours
        ticket_id = TeksatService.new(customer: customer).authenticate({ url: url, customer_id: cust_id, username: username, password: password})
        session[:teksat_ticket_id] = ticket_id
        session[:teksat_authenticated_at] = Time.now.to_i
      end
    end

    def teksat_sync_vehicles customer, ticket_id
      teksat_vehicles = TeksatService.new(customer: customer, ticket_id: ticket_id).list_devices
      vehicles = customer.vehicles.take [teksat_vehicles.length, customer.vehicles.count].min
      vehicles.each_with_index{|vehicle, index| vehicle.update!(teksat_id: teksat_vehicles[index][:id]) }
    end

    def tomtom_authenticate customer
      account  = params[:tomtom_account]  ? params[:tomtom_account]   : customer.try(:tomtom_account)
      user     = params[:tomtom_user]     ? params[:tomtom_user]      : customer.try(:tomtom_user)
      passwd   = params[:tomtom_password] ? params[:tomtom_password]  : customer.try(:tomtom_password)
      TomtomService.new(customer: customer).test_list(account: account, user: user, password: passwd)
    end

    def tomtom_sync_vehicles customer
      tomtom_vehicles = TomtomService.new(customer: customer).list_vehicles
      tomtom_vehicles = tomtom_vehicles.select{|item| !item[:objectUid].blank? }
      vehicles = customer.vehicles.take [tomtom_vehicles.length, customer.vehicles.count].min
      vehicles.each_with_index do |vehicle, index|
        vehicle.update!(tomtom_id: tomtom_vehicles[index][:objectUid], fuel_type: tomtom_vehicles[index][:fuelType], color: tomtom_vehicles[index][:color])
      end
    end
  end
end
