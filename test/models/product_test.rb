require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  test 'should not save' do
    o = customers(:customer_one).products.build
    assert_not o.save, 'Saved without required fields'
  end

  test 'should save' do
    o = customers(:customer_one).products.build(name: 'plop', code: 'P')
    assert o.save
  end
end
