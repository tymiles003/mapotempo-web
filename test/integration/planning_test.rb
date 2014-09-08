require 'test_helper'

class PlanningsTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner.clean
    Capybara.reset!
    login
  end

  test 'add' do
    # Create planning
    visit new_planning_path
    fill_in 'planning[name]', with: 'P'
    find('.select2-container input').set('tag1')
    find('li.select2-result:first-child').click
    submit

    assert_selector '.alert-success'

    assert_equal 'P', find_field('planning[name]').value
    within(:css, '.select2-choices') do
        assert_text('tag1')
    end

    first('.route')
    assert_selector '.route', count: 2
    assert_selector '.route:nth-child(1) .stops li', count: 3
    assert_selector '.route:nth-child(2) .stops li', count: 2
  end

  test 'edit' do
    # Open planning
    visit plannings_path
    assert_not first(:css, '#refresh')
    find('tr', text: 'planning1').find('.icon-edit').click

    # Edit destination
    find('.route:nth-child(2) .stops li:nth-child(2) a:nth-child(1)').click
    first '[data-controller=destinations]'
    assert_selector '[data-controller=destinations]'
    fill_in 'destination[city]', with: 'Brest'
    submit

    # Back
    assert_selector '[data-controller=plannings]'

    # Check out of date
    assert_selector '#refresh'
    find('#refresh').click
    sleep 1
    assert_not first(:css, '#refresh')

    # Edit zoning
    find('#zoning_edit').click
    find('.zone:last-child .delete').click
    submit

    # Back
    assert_selector '[data-controller=plannings]'

    # Check out of date
    assert_selector '#refresh'
    find('#refresh').click
    sleep 1
    assert_not first(:css, '#refresh')
  end

  test 'automatic insert' do
    # Open planning
    visit plannings_path
    assert_not first(:css, '#refresh')
    find('tr', text: 'planning1').find('.icon-edit').click

    # Automatic insert
    assert_selector '.route:nth-child(1) .stops li', count: 1
    assert_selector '.route:nth-child(2) .stops li', count: 4
    find('.route:nth-child(1) .stops li:nth-child(1) button:nth-child(1)').click
    assert_selector '.route:nth-child(1) .stops li', count: 0
    assert_selector '.route:nth-child(2) .stops li', count: 5
  end
end
