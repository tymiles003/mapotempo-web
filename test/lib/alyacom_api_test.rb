require 'alyacom_api'

class AlyacomApiTest < ActionController::TestCase
  setup do
    @customer = customers(:customer_one)
    @customer.alyacom_association = 'asso'
  end

  def around
    begin
      url = Mapotempo::Application.config.alyacom_api_url
      uri_template = Addressable::Template.new(url + '/asso/staff?apiKey={apikey}&enc=json')
      stub_staff_get = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/../web_mocks/alyacom.fr/staff.json').read)

      uri_template = Addressable::Template.new(url + '/asso/staff?apiKey={apikey}&enc=json')
      stub_staff_post = stub_request(:post, uri_template).to_return("HTTP/1.1 200 OK\n\n")

      uri_template = Addressable::Template.new(url + '/asso/users?apiKey={apikey}&enc=json')
      stub_users_1 = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/../web_mocks/alyacom.fr/users-1.json').read)

      uri_template = Addressable::Template.new('http://app.alyacom.fr/ws/__id__/users?apiKey={apikey}&enc=json&page=2')
      stub_users_2 = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/../web_mocks/alyacom.fr/users-2.json').read)

      uri_template = Addressable::Template.new(url + '/asso/users?apiKey={apikey}&enc=json')
      stub_users_post = stub_request(:post, uri_template).to_return("HTTP/1.1 200 OK\n\n")

      uri_template = Addressable::Template.new(url + '/asso/planning?apiKey={apikey}&enc=json&fromDate={date}&idStaff=v')
      stub_planning_get = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../', __FILE__) + '/../web_mocks/alyacom.fr/planning.json').read)

      uri_template = Addressable::Template.new(url + '/asso/planning?apiKey={apikey}&enc=json')
      stub_planning_post = stub_request(:post, uri_template).to_return("HTTP/1.1 200 OK\n\n")

      yield
    ensure
      remove_request_stub(stub_staff_get)
      remove_request_stub(stub_staff_post)
      remove_request_stub(stub_users_1)
      remove_request_stub(stub_users_2)
      remove_request_stub(stub_users_post)
      remove_request_stub(stub_planning_get)
      remove_request_stub(stub_planning_post)
    end
  end

  test 'shoud createJobRoute' do
    ret = AlyacomApi.createJobRoute(@customer.alyacom_association, Date.today, {
      id: 'v',
      name: 'v',
      street: 'avenue de la République',
      postalcode: '75000',
      city: 'Paris',
    }, [{
      user: {
        id: 'idUser1',
        name: 'MONSIEUR 1',
        street: 'rue',
        postalcode: '75000',
        city: 'PARIS',
        detail: '',
        comment: ''
      },
      planning: {
        id: '1',
        staff_id: 'v',
        destination_id: '001',
        comment: '',
        start: Time.now,
        end: Time.now + 10
      }
      }])
    assert ret
  end
end
