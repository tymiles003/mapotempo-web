class TomtomWebfleetTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
    @customer.tomtom_account = 'riri'
    @customer.tomtom_user = 'fifi'
    @customer.tomtom_password = 'loulou'

    @tomtom = Mapotempo::Application.config.tomtom
  end

  test 'shoud showObjectReport' do
    begin
      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/{version}/objectsAndPeopleReportingService?wsdl')
      stub_wsdl = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/soap.business.tomtom.com/objectsAndPeopleReportingService.wsdl').read)

      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/{version}/objectsAndPeopleReportingService')
      stub = stub_request(:post, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/soap.business.tomtom.com/objectsAndPeopleReportingService.xml').read)

      ret = @tomtom.showObjectReport(@customer.tomtom_account, @customer.tomtom_user, @customer.tomtom_password)
      assert ret
    ensure
      remove_request_stub(stub)
      remove_request_stub(stub_wsdl)
    end
  end
end
