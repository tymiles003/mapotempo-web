require 'test_helper'

class V01::ProductsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  def app
    Rails.application
  end

  setup do
    @product = products(:product_one)
  end

  def api(part = nil, param = {})
    part = part ? '/' + part.to_s : ''
    "/api/0.1/products#{part}.json?api_key=testkey1&" + param.collect{ |k, v| "#{k}=" + URI.escape(v.to_s) }.join('&')
  end

  test 'should return customer''s products' do
    get api()
    assert last_response.ok?, last_response.body
    assert_equal @product.customer.products.size, JSON.parse(last_response.body).size
  end

  test 'should return customer''s products by ids' do
    get api(nil, 'ids' => @product.id)
    assert last_response.ok?, last_response.body
    assert_equal 1, JSON.parse(last_response.body).size
    assert_equal @product.id, JSON.parse(last_response.body)[0]['id']
  end

  test 'should return a product' do
    get api(@product.id)
    assert last_response.ok?, last_response.body
    assert_equal @product.name, JSON.parse(last_response.body)['name']
  end

  test 'should create a product' do
    assert_difference('Product.count', 1) do
      @product.name = 'new name'
      @product.code = 'new code'
      post api(), @product.attributes
      assert last_response.created?, last_response.body
    end
  end

  test 'should update a product' do
    @product.name = 'new name'
    put api(@product.id), @product.attributes
    assert last_response.ok?, last_response.body

    get api(@product.id)
    assert last_response.ok?, last_response.body
    assert_equal @product.name, JSON.parse(last_response.body)['name']
  end

  test 'should destroy a product' do
    assert_difference('Product.count', -1) do
      delete api(@product.id)
      assert last_response.ok?, last_response.body
    end
  end

  test 'should destroy multiple products' do
    assert_difference('Product.count', -2) do
      delete api + "&ids=#{products(:product_one).id},#{products(:product_two).id}"
      assert last_response.ok?, last_response.body
    end
  end
end
