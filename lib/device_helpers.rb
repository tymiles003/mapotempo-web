module DeviceHelpers

  def orange_fleet_authenticate customer
    user     = params[:orange_user]     ? params[:orange_user]      : customer.try(:orange_user)
    passwd   = params[:orange_password] ? params[:orange_password]  : customer.try(:orange_password)
    OrangeService.new(auth: { user: user, password: passwd }).test_list
  end

  def orange_sync_vehicles customer
    orange_vehicles = OrangeService.new(customer: customer).list
    vehicles = customer.vehicles.take [orange_vehicles.length, customer.vehicles.count].min
    vehicles.each_with_index{|vehicle, index| vehicle.update!(orange_id: orange_vehicles[index][:id]) }
  end

  def teksat_authenticate customer
    url      = params[:teksat_url]         ? params[:teksat_url]         : customer.try(:teksat_url)
    cust_id  = params[:teksat_customer_id] ? params[:teksat_customer_id] : customer.try(:teksat_customer_id)
    username = params[:teksat_username]    ? params[:teksat_username]    : customer.try(:teksat_username)
    password = params[:teksat_password]    ? params[:teksat_password]    : customer.try(:teksat_password)
    if params[:check_only].to_i == 1 || !session[:teksat_ticket_id] || (Time.now - Time.at(session[:teksat_authenticated_at])) > 3.hours
      ticket_id = TeksatService.new(customer: customer).auth url, cust_id, username, password
      session[:teksat_ticket_id] = ticket_id
      session[:teksat_authenticated_at] = Time.now.to_i
    end
  end

  def teksat_sync_vehicles customer, ticket_id
    teksat_vehicles = TeksatService.new(customer: customer, ticket_id: ticket_id).list
    vehicles = customer.vehicles.take [teksat_vehicles.length, customer.vehicles.count].min
    vehicles.each_with_index{|vehicle, index| vehicle.update!(teksat_id: teksat_vehicles[index][:id]) }
  end

  def tomtom_authenticate customer
    account  = params[:tomtom_account]  ? params[:tomtom_account]   : customer.try(:tomtom_account)
    user     = params[:tomtom_user]     ? params[:tomtom_user]      : customer.try(:tomtom_user)
    passwd   = params[:tomtom_password] ? params[:tomtom_password]  : customer.try(:tomtom_password)
    Mapotempo::Application.config.tomtom.showObjectReport account, user, passwd
  end

  def tomtom_sync_vehicles customer
    tomtom_vehicles = Mapotempo::Application.config.tomtom.showVehicleReport customer.tomtom_account, customer.tomtom_user, customer.tomtom_password
    tomtom_vehicles = tomtom_vehicles.select{|item| !item[:objectUid].blank? }
    vehicles = customer.vehicles.take [tomtom_vehicles.length, customer.vehicles.count].min
    vehicles.each_with_index{|vehicle, index| vehicle.update!(tomtom_id: tomtom_vehicles[index][:objectUid]) }
  end

end
