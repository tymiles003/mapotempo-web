require 'test_helper'

class TagTest < ActiveSupport::TestCase

  test 'should not save' do
    tag = customers(:customer_one).tags.build
    assert_not tag.save, 'Saved without required fields'
  end

  test 'should not save with invalid ref' do
    tag = customers(:customer_one).tags.build(ref: 'test/test')
    assert_not tag.save, 'Saved with bad ref fields'
  end

  test 'should not save color' do
    tag = customers(:customer_one).tags.build(label: 'plop', color: 'red')
    assert_not tag.save, 'Saved with invalid color'
  end

  test 'should save' do
    tag = customers(:customer_one).tags.build(label: 'plop', color: '#ff0000', icon: 'diamon')
    assert tag.save
  end
end
