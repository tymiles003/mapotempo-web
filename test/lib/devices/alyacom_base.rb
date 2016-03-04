module AlyacomBase

  def set_route
    @route = routes(:route_one_one)
    @route.update! end: @route.start + 5.hours
    @route.planning.update! date: 10.days.from_now
  end

  def add_alyacom_credentials customer
    customer.enable_alyacom = true
    customer.alyacom_association = "alyacom_association"
    customer.save!
    customer
  end

  def with_stubs values, &block
    begin
      stubs = []
      values.each do |method, names|
        names.each do |name|
          case name
            when :staff, :users, :planning
              expected_response = File.read(Rails.root.join("test/web_mocks/alyacom.fr/#{name}.json")).strip
              api_url = URI.parse Mapotempo::Application.config.devices.alyacom.api_url
              url = [api_url, @customer.alyacom_association, name.to_s].join "/"
              stubs << stub_request(method, url).with(query: hash_including({ })).to_return(status: 200, body: "{}")
          end
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
