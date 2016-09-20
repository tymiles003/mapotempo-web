require 'test_helper'

class V01::DeliverableUnitsTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  setup do
    @deliverable_unit = deliverable_units(:deliverable_unit_one_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/deliverable_units#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return customer''s deliverable units' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @deliverable_unit.customer.deliverable_units.size, JSON.parse(last_response.body).size
  end

  test 'should return customer''s deliverable units by ids' do
    get api(nil, 'ids' => @deliverable_unit.id)
    assert last_response.ok?, last_response.body
    assert_equal 1, JSON.parse(last_response.body).size
    assert_equal @deliverable_unit.id, JSON.parse(last_response.body)[0]['id']
  end

  test 'should return a deliverable unit' do
    get api(@deliverable_unit.id)
    assert last_response.ok?, last_response.body
    assert_equal @deliverable_unit.label, JSON.parse(last_response.body)['label']
  end

  test 'should create a deliverable unit' do
    assert_difference('DeliverableUnit.count', 1) do
      @deliverable_unit.label = 'new label'
      post api(), @deliverable_unit.attributes
      assert last_response.created?, last_response.body
    end
  end

  test 'should update a deliverable unit' do
    @deliverable_unit.label = 'new label'
    put api(@deliverable_unit.id), label: 'riri'
    assert last_response.ok?, last_response.body

    get api(@deliverable_unit.id)
    assert last_response.ok?, last_response.body
    assert_equal 'riri', JSON.parse(last_response.body)['label']
  end

  test 'should destroy a deliverable unit' do
    assert_difference('DeliverableUnit.count', -1) do
      delete api(@deliverable_unit.id)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should destroy multiple deliverable units' do
    assert_difference('DeliverableUnit.count', -2) do
      delete api + "&ids=#{deliverable_units(:deliverable_unit_one_one).id},#{deliverable_units(:deliverable_unit_one_two).id}"
      assert last_response.ok?, last_response.body
    end
  end
end
