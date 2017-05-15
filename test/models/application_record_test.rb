require 'test_helper'

class ApplicationRecordTest < ActiveSupport::TestCase
  test 'precision of second for created_at' do
    customer = customers(:customer_one)

    destination = customer.destinations.create(name:'e',lat:1,lng:1)
    visit = destination.visits.create()
    destination.save!
    visit.save!

    created_at = visit.created_at
    updated_at = visit.created_at

    visit.reload

    assert_equal created_at, visit.created_at
    assert_equal updated_at, visit.updated_at
  end
end
