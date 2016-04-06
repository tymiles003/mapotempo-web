module Devices
  module Helpers
    def device_send_route options={}
      route = Route.for_customer(@customer).find params[:route_id]
      service.send_route route, options
      present route, with: V01::Entities::DeviceRouteLastSentAt
    end

    def device_send_routes options={}
      planning = @customer.plannings.find params[:planning_id]
      routes = planning.routes.select(&:vehicle_usage)
      routes = routes.select{|route| route.vehicle_usage.vehicle.send(options[:device_id]) } if options[:device_id]
      routes.each{|route| service.send_route(route, options) }
      present routes, with: V01::Entities::DeviceRouteLastSentAt
    end

    def device_clear_route options={}
      route = Route.for_customer(@customer).find params[:route_id]
      service.clear_route route
      present route, with: V01::Entities::DeviceRouteLastSentAt
    end

    def device_clear_routes options={}
      planning = @customer.plannings.find params[:planning_id]
      routes = planning.routes.select(&:vehicle_usage)
      routes = routes.select{|route| route.vehicle_usage.vehicle.send(options[:device_id]) } if options[:device_id]
      routes.each{|route| service.clear_route(route) }
      present routes, with: V01::Entities::DeviceRouteLastSentAt
    end

    def orange_fleet_authenticate customer
      OrangeService.new(customer: customer).test_list orange_credentials(customer)
    end

    def orange_credentials customer
      user   = params[:orange_user]     ? params[:orange_user]      : customer.try(:orange_user)
      passwd = params[:orange_password] ? params[:orange_password]  : customer.try(:orange_password)
      return { user: user, password: passwd }
    end

    def orange_sync_vehicles customer
      orange_vehicles = OrangeService.new(customer: customer).list_devices orange_credentials(customer)
      customer.vehicles.update_all orange_id: nil
      orange_vehicles.each_with_index do |vehicle, index|
        next if !customer.vehicles[index]
        customer.vehicles[index].update! orange_id: vehicle[:id]
      end
    end

    def teksat_authenticate customer
      if params[:check_only].to_i == 1 || !session[:teksat_ticket_id] || (Time.now - Time.at(session[:teksat_authenticated_at])) > 3.hours
        ticket_id = TeksatService.new(customer: customer).authenticate teksat_credentials(customer)
        session[:teksat_ticket_id] = ticket_id
        session[:teksat_authenticated_at] = Time.now.to_i
      end
    end

    def teksat_credentials customer
      url      = params[:teksat_url]         ? params[:teksat_url]         : customer.try(:teksat_url)
      cust_id  = params[:teksat_customer_id] ? params[:teksat_customer_id] : customer.try(:teksat_customer_id)
      username = params[:teksat_username]    ? params[:teksat_username]    : customer.try(:teksat_username)
      password = params[:teksat_password]    ? params[:teksat_password]    : customer.try(:teksat_password)
      return { url: url, customer_id: cust_id, username: username, password: password }
    end

    def teksat_sync_vehicles customer, ticket_id
      teksat_vehicles = TeksatService.new(customer: customer, ticket_id: ticket_id).list_devices
      customer.vehicles.update_all teksat_id: nil
      teksat_vehicles.each_with_index do |vehicle, index|
        next if !customer.vehicles[index]
        customer.vehicles[index].update! teksat_id: vehicle[:id]
      end
    end

    def tomtom_authenticate customer
      TomtomService.new(customer: customer).test_list tomtom_credentials(customer)
    end

    def tomtom_credentials customer
      account = params[:tomtom_account]  ? params[:tomtom_account]   : customer.try(:tomtom_account)
      user    = params[:tomtom_user]     ? params[:tomtom_user]      : customer.try(:tomtom_user)
      passwd  = params[:tomtom_password] ? params[:tomtom_password]  : customer.try(:tomtom_password)
      return { account: account, user: user, password: passwd }
    end

    def tomtom_sync_vehicles customer
      tomtom_vehicles = TomtomService.new(customer: customer).list_vehicles tomtom_credentials(customer)
      tomtom_vehicles = tomtom_vehicles.select{|item| !item[:objectUid].blank? }
      customer.vehicles.update_all tomtom_id: nil
      tomtom_vehicles.each_with_index do |vehicle, index|
        next if !customer.vehicles[index]
        customer.vehicles[index].update! tomtom_id: vehicle[:objectUid], fuel_type: vehicle[:fuelType], color: vehicle[:color]
      end
    end

    def alyacom_credentials customer
      alyacom_association = params[:alyacom_association] ? params[:alyacom_association] : customer.try(:alyacom_association)
      alyacom_api_key     = params[:alyacom_api_key]     ? params[:alyacom_api_key]     : customer.try(:alyacom_api_key)
      return { alyacom_association: alyacom_association, alyacom_api_key: alyacom_api_key }
    end

    def alyacom_authenticate customer
      AlyacomService.new(customer: customer).test_list alyacom_credentials(customer)
    end

  end
end
