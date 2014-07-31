require 'test_helper'

class DestinationsTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner.clean
    Capybara.reset!
    login
  end

  test 'filter' do
    visit destinations_path
    assert_selector 'tbody tr', count: 3

    find('.tablesorter-filter-row td:nth-child(1) input').set('a')
    assert_selector 'tbody tr', count: 1
    find('.tablesorter-filter-row td:nth-child(1) input').set('')

    find('.tablesorter-filter-row td:nth-child(4) input').set('1')
    assert_selector 'tbody tr', count: 2
    find('.tablesorter-filter-row td:nth-child(4) input').set('')
  end

  test 'add' do
    visit destinations_path
    assert_selector 'tbody tr', count: 3
    find('#add').click
    assert_selector 'tbody tr', count: 4

    find('tbody tr:last-child td:nth-child(2) input').set('test')

    visit destinations_path
    assert_selector 'tbody tr', count: 4
    find('tr:last-child .destroy').click
    alert_accept
    assert_selector 'tbody tr', count: 3
  end
end
