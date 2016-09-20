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
    v.open1 = v.close1 = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    d.save!
  end

  test 'should set invalid TW' do
    d = destinations(:destination_one)
    v = d.visits[0]
    v.open1 = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    v.close1 = Time.new(2000, 01, 01, 00, 9, 00, '+00:00')
    assert !d.save

    v.open1 = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    v.open2 = Time.new(2000, 01, 01, 00, 11, 00, '+00:00')
    assert !d.save

    v.open1 = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    v.close1 = Time.new(2000, 01, 01, 00, 11, 00, '+00:00')
    v.open2 = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    assert !d.save

    v.open1 = Time.new(2000, 01, 01, 00, 10, 00, '+00:00')
    v.close1 = Time.new(2000, 01, 01, 00, 11, 00, '+00:00')
    v.open1 = Time.new(2000, 01, 01, 00, 12, 00, '+00:00')
    v.close2 = Time.new(2000, 01, 01, 00, 11, 00, '+00:00')
    assert !d.save
  end

  test 'should support localized number separator' do
    orig_locale = I18n.locale
    visit = visits :visit_one

    begin
      I18n.locale = :en
      assert I18n.locale == :en
      visit.update! quantities: {1 => nil}
      assert visit.localized_quantities[1].nil? # Don't crash with nil values
      visit.update! quantities: {1 => "10.5"} # Assign with localized separator
      assert_equal 10.5, visit.quantities[1]
      assert_equal "10.5", visit.localized_quantities[1] # Localized value
      visit.update! quantities: {1 => 10}
      assert_equal 10, visit.quantities[1]
      assert_equal "10", visit.localized_quantities[1] # Remove trailing zeros
      visit.update! quantities: {1 => 10.1} # Assign without localized separator
      assert_equal 10.1, visit.quantities[1]

      I18n.locale = :fr
      assert I18n.locale == :fr
      visit.update! quantities: {1 => nil}
      assert visit.localized_quantities[1].nil? # Don't crash with nil values
      visit.update! quantities: {1 => "10,5"} # Assign with localized separator
      assert_equal 10.5, visit.quantities[1]
      assert_equal "10,5", visit.localized_quantities[1] # Localized value
      visit.update! quantities: {1 => 10}
      assert_equal 10, visit.quantities[1]
      assert_equal "10", visit.localized_quantities[1] # Remove trailing zeros
      visit.update! quantities: {1 => 10.1} # Assign without localized separator
      assert_equal 10.1, visit.quantities[1]
    ensure
      I18n.locale = orig_locale
    end
  end

end
