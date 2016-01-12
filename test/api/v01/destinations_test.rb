require 'test_helper'

class V01::DestinationsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include ActionDispatch::TestProcess
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @destination = destinations(:destination_one)
  end

  def around
    Routers::Osrm.stub_any_instance(:compute, [1000, 60, 'trace']) do
      yield
    end
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/destinations#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return customer''s destinations' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @destination.customer.destinations.size, JSON.parse(last_response.body).size
  end

  test 'should return customer''s destinations by ids' do
    get api(nil, 'ids' => @destination.id)
    assert last_response.ok?, last_response.body
    assert_equal 1, JSON.parse(last_response.body).size
    assert_equal @destination.id, JSON.parse(last_response.body)[0]['id']
  end

  test 'should return a destination' do
    get api(@destination.id)
    assert last_response.ok?, last_response.body
    assert_equal @destination.name, JSON.parse(last_response.body)['name']
  end

  test 'should create' do
    assert_difference('Destination.count', 1) do
      assert_difference('Stop.count', 0) do
        @destination.name = 'new dest'
        post api(), @destination.attributes.update({tag_ids: tags})
        assert last_response.created?, last_response.body
        assert_equal @destination.name, JSON.parse(last_response.body)['name']
      end
    end
  end

  test 'should create with none tag' do
    ['', nil, []].each do |tags|
      assert_difference('Destination.count', 1) do
        @destination.name = 'new dest'
        post api(), @destination.attributes.update({tag_ids: tags})
        assert last_response.created?, last_response.body
      end
    end
  end

  test 'should create bulk from csv' do
    assert_difference('Destination.count', 1) do
      assert_difference('Planning.count', 1) do
        put api(), replace: false, file: fixture_file_upload('files/import_destinations_one.csv', 'text/csv')
        assert last_response.ok?, last_response.body
        assert_equal 1, JSON.parse(last_response.body).size

        get api('ref:z')
        assert_equal 1, JSON.parse(last_response.body)['tag_ids'].size
      end
    end
  end

  test 'should create bulk from json' do
    assert_difference('Destination.count', 1) do
      assert_difference('Planning.count', 1) do
        put api(), {destinations: [{
          name: 'Nouveau client',
          street: nil,
          postalcode: nil,
          city: 'Tule',
          lat: 43.5710885456786,
          lng: 3.89636993408203,
          quantity: nil,
          open: nil,
          close: nil,
          detail: nil,
          comment: nil,
          phone_number: nil,
          ref: 'z',
          take_over: nil,
          tags: ['tag1', 'tag2'],
          geocoding_accuracy: nil,
          foo: 'bar',
          route: '1',
          active: '1'
        }]}
        assert last_response.ok?, last_response.body
        assert_equal 1, JSON.parse(last_response.body).size

        get api('ref:z')
        assert_equal 2, JSON.parse(last_response.body)['tag_ids'].size
      end
    end
  end

  test 'should create bulk from tomtom' do
    begin
      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/{version}/addressService?wsdl')
      stub_address_wsdl = stub_request(:get, uri_template).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/soap.business.tomtom.com/addressService.wsdl').read)

      uri_template = Addressable::Template.new('https://soap.business.tomtom.com/{version}/addressService')
      stub = stub_request(:post, uri_template).to_return(File.new(File.expand_path('../../../web_mocks/', __FILE__) + '/soap.business.tomtom.com/showAddressReportResponse.xml').read)

      assert_difference('Destination.count', 1) do
        put api(), replace: false, remote: :tomtom
        assert_equal 202, last_response.status, 'Bad response: ' + last_response.body
      end
    ensure
      remove_request_stub(stub)
      remove_request_stub(stub_address_wsdl)
    end
  end

  test 'should update a destination' do
    [
      tags(:tag_one).id.to_s + ',' + tags(:tag_two).id.to_s,
      [tags(:tag_one).id, tags(:tag_two).id],
      '',
      nil,
      []
    ].each do |tags|
      @destination.name = 'new name'
      put api(@destination.id), @destination.attributes.update({tag_ids: tags})
      assert last_response.ok?, last_response.body

      get api(@destination.id)
      assert last_response.ok?, last_response.body
      assert_equal @destination.name, JSON.parse(last_response.body)['name']
    end
  end

  test 'should destroy a destination' do
    assert_difference('Destination.count', -1) do
      delete api(@destination.id)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should destroy multiple destinations' do
    assert_difference('Destination.count', -2) do
      delete api + "&ids=#{destinations(:destination_one).id},#{destinations(:destination_two).id}"
      assert last_response.ok?, last_response.body
    end
  end

  test 'should geocode' do
    patch api('geocode'), format: :json, destination: { city: @destination.city, name: @destination.name, postalcode: @destination.postalcode, street: @destination.street }
    assert last_response.ok?, last_response.body
  end

  test 'should geocode complete' do
    patch api('geocode_complete'), format: :json, id: @destination.id, destination: { city: 'Montpellier', street: 'Rue de la Chaînerais' }
    assert last_response.ok?, last_response.body
  end
end
