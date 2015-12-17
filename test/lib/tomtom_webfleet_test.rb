class TomtomWebfleetTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
    @customer.tomtom_account = 'riri'
    @customer.tomtom_user = 'fifi'
    @customer.tomtom_password = 'loulou'

    @tomtom = Mapotempo::Application.config.tomtom
  end

  def around
    begin
      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/{version}/objectsAndPeopleReportingService?wsdl')
      stub_object_wsdl = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/../web_mocks/soap.business.tomtom.com/objectsAndPeopleReportingService.wsdl').read)

      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/{version}/addressService?wsdl')
      stub_address_wsdl = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/../web_mocks/soap.business.tomtom.com/addressService.wsdl').read)

      yield
    ensure
      remove_request_stub(stub_address_wsdl)
      remove_request_stub(stub_object_wsdl)
    end
  end

  test 'shoud showObjectReport' do
    begin
      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/{version}/objectsAndPeopleReportingService')
      stub = stub_request(:post, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/../web_mocks/soap.business.tomtom.com/showObjectReportResponse.xml').read)

      ret = @tomtom.showObjectReport(@customer.tomtom_account, @customer.tomtom_user, @customer.tomtom_password)
      assert ret
    ensure
      remove_request_stub(stub)
    end
  end

  test 'shoud showVehicleReport' do
    begin
      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/{version}/objectsAndPeopleReportingService')
      stub = stub_request(:post, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/../web_mocks/soap.business.tomtom.com/showVehicleReportResponse.xml').read)

      ret = @tomtom.showVehicleReport(@customer.tomtom_account, @customer.tomtom_user, @customer.tomtom_password)
      assert ret
    ensure
      remove_request_stub(stub)
    end
  end

  test 'shoud showAddressReport' do
    begin
      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/{version}/addressService')
      stub = stub_request(:post, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/../web_mocks/soap.business.tomtom.com/showAddressReportResponse.xml').read)

      ret = @tomtom.showAddressReport(@customer.tomtom_account, @customer.tomtom_user, @customer.tomtom_password)
      assert ret
    ensure
      remove_request_stub(stub)
    end
  end
end
