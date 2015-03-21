require 'test_helper'

class V01::DestinationsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include ActionDispatch::TestProcess
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @destination = destinations(:destination_one)
  end

  def api(part = nil)
    part = part ? '/' + part.to_s : ''
    "/api/0.1/destinations#{part}.json?api_key=testkey1"
  end

  test 'should return customer''s destinations' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @destination.customer.destinations.size, JSON.parse(last_response.body).size
  end

  test 'should return a destination' do
    get api(@destination.id)
    assert last_response.ok?, last_response.body
    assert_equal @destination.name, JSON.parse(last_response.body)['name']
  end

  test 'should return a destination by ref' do
    get api("ref:#{@destination.ref}")
    assert last_response.ok?, last_response.body
    assert_equal @destination.ref, JSON.parse(last_response.body)['ref']
  end

  test 'should create' do
    assert_difference('Destination.count', 1) do
      assert_difference('Stop.count', 1) do
        @destination.name = 'new dest'
        post api(), @destination.attributes.update({tag_ids: [tags(:tag_one).id]})
        assert last_response.created?, last_response.body
      end
    end
  end

  test 'should create bulk from csv' do
    assert_difference('Destination.count', 1) do
      put api(), replace: false, file: fixture_file_upload('files/import_one.csv', 'text/csv')
      assert_equal 204, last_response.status
    end
  end

  test 'should create bulk from json' do
    assert_difference('Destination.count', 1) do
      put api(), {destinations: [{
        name: "Nouveau client",
        street: nil,
        postalcode: nil,
        city: "Tule",
        lat: 43.5710885456786,
        lng: 3.89636993408203,
        quantity: nil,
        open: nil,
        close: nil,
        detail: nil,
        comment: nil,
        ref: nil,
        take_over: nil,
        tag_ids: [],
        geocoding_accuracy: nil,
        foo: 'bar'
      }]}
      assert_equal 204, last_response.status
    end
  end

  test 'should destroy a destination' do
    assert_difference('Destination.count', -1) do
      delete api(@destination.id)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should :geocode' do
    patch api('geocode'), format: :json, destination: { city: @destination.city, name: @destination.name, postalcode: @destination.postalcode, street: @destination.street }
    assert last_response.ok?, last_response.body
  end

  test 'should geocode complete' do
    patch api('geocode_complete'), format: :json, id: @destination.id, destination: { city: 'Montpellier', street: 'Rue de la Chaînerais' }
    assert last_response.ok?, last_response.body
  end
end
