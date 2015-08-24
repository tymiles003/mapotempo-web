require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test 'should not save' do
    o = customers(:customer_one).products.build
    assert_not o.save, 'Saved without required fields'
  end

  test 'should save' do
    o = customers(:customer_one).products.build(name: 'plop', code: 'P')
    assert o.save
  end
end
