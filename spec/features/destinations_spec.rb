require 'rails_helper'
require 'capybara_helper'

feature :destination do
  fixtures :all

  before :each do
    login
  end

  scenario 'filter', js: true do
    visit destinations_path
    expect(page).to have_selector('tbody tr', count: 3)

    find('.tablesorter-filter-row td:nth-child(1) input').set('a')
    expect(page).to have_selector('tbody tr', count: 1)
    find('.tablesorter-filter-row td:nth-child(1) input').set('')

    find('.tablesorter-filter-row td:nth-child(4) input').set('1')
    expect(page).to have_selector('tbody tr', count: 2)
    find('.tablesorter-filter-row td:nth-child(4) input').set('')
  end

  scenario 'add', js: true do
    visit destinations_path
    expect(page).to have_selector('tbody tr', count: 3)
    find('#add').click
    expect(page).to have_selector('tbody tr', count: 4)

    find('tbody tr:last-child td:nth-child(2) input').set('test')

    visit destinations_path
    expect(page).to have_selector('tbody tr', count: 4)
    find('tr:last-child .destroy').click
    alert_accept
    expect(page).to have_selector('tbody tr', count: 3)
  end
end
