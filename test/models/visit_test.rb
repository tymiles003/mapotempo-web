require 'test_helper'

class VisitTest < ActiveSupport::TestCase
  set_fixture_class delayed_jobs: Delayed::Backend::ActiveRecord::Job

  test 'should not save' do
    o = Visit.new
    assert_not o.save, 'Saved without required fields'
  end

  test 'should update add tag' do
    d = destinations(:destination_one)
    stops(:stop_three_one).destroy
    assert_difference('Stop.count') do
      d.visits[0].tags << tags(:tag_two)
      d.save!
      d.customer.save!
    end
  end

  test 'should update remove tag' do
    d = destinations(:destination_one)
    stops(:stop_three_one).destroy
    assert_difference('Stop.count', -1) do
      d.visits[0].tags = []
      d.save!
      d.customer.save!
    end
  end

  test 'should update tag' do
    d = destinations(:destination_one)
    p = plannings(:planning_one)
    stops(:stop_three_one).destroy
    p.tags = [tags(:tag_one), tags(:tag_two)]

    routes(:route_one_one).stops.clear
    d.visits[0].tags = []

    assert_difference('Stop.count', 0) do
      d.visits[0].tags = [tags(:tag_one)]
      d.save!
      d.customer.save!
    end

    assert_difference('Stop.count', 2) do
      d.visits[0].tags = [tags(:tag_one), tags(:tag_two)]
      d.save!
      d.customer.save!
    end
  end

  test 'should set same start and close' do
    d = destinations(:destination_one)
    v = d.visits[0]
    v.open = v.close = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    d.save!
  end
end
