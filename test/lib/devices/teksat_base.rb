module TeksatBase

  def set_route
    @route = routes(:route_one_one)
    @route.update! end: @route.start + 5.hours
    @route.planning.update! date: 10.days.from_now
    @vehicle = @route.vehicle_usage.vehicle
    @vehicle.update! teksat_id: "1091"
  end

  def add_teksat_credentials customer
    customer.enable_teksat = true
    customer.teksat_customer_id = rand(100)
    customer.teksat_username = "teksat_username"
    customer.teksat_password = "teksat_password"
    customer.teksat_url = "www.gps00.teksat.fr"
    customer.save!
    customer
  end

  def with_stubs names, &block
    begin
      stubs = []
      names.each do |name|
        case name
          when :auth
            @ticket_id = File.read(Rails.root.join("test/web_mocks/teksat/get_ticket")).strip
            teksat_service = TeksatService.new(customer: @customer).service
            teksat_service.auth = { url: @customer.teksat_url, customer_id: @customer.teksat_customer_id, username: @customer.teksat_username, password: @customer.teksat_password }
            url = teksat_service.send :get_ticket_url
            stubs << stub_request(:get, url).to_return(status: 200, body: @ticket_id)
          when :get_vehicles
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/get_vehicles.xml")).strip
            url = TeksatService.new(customer: @customer, ticket_id: @ticket_id).service.send :get_vehicles_url
            stubs << stub_request(:get, url).to_return(status: 200, body: expected_response)
          when :vehicles_pos
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/get_vehicles_pos.xml")).strip
            url = TeksatService.new(customer: @customer, ticket_id: @ticket_id).service.send :get_vehicles_pos_url
            stubs << stub_request(:get, url).to_return(status: 200, body: expected_response)
          when :send_route
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/mission_data.xml")).strip
            url = @customer.teksat_url + "/webservices/map/set-mission.jsp"
            stubs << stub_request(:get, url).with(:query => hash_including({ })).to_return(status: 200, body: expected_response)
          when :clear_route
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/get_missions.xml")).strip
            url = @customer.teksat_url + "/webservices/map/get-missions.jsp"
            stubs << stub_request(:get, url).with(:query => hash_including({ })).to_return(status: 200, body: expected_response)
            expected_response = File.read(Rails.root.join("test/web_mocks/teksat/mission_data.xml")).strip
            url = @customer.teksat_url + "/webservices/map/delete-mission.jsp"
            stubs << stub_request(:get, url).with(:query => hash_including({ })).to_return(status: 200, body: expected_response)
        end
      end
      yield
    ensure
      stubs.each do |name|
        remove_request_stub name
      end
    end
  end
end
