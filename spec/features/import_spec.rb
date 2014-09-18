require 'rails_helper'
require 'capybara_helper'

feature :import do
  fixtures :all

  before :each do
    login
  end

  scenario 'import', js: true do
    visit destination_import_path
    if Capybara.javascript_driver == :webkit
      evaluate_script("$('#destinations_import_model_file').attr('style','')") # capybara-webkit workaround
    end
    attach_file 'destinations_import_model[file]', Rails.root.join('spec/fixtures/files/import_many-utf-8.csv')
    check 'destinations_import_model[replace]'
    submit

    first 'tbody tr'
    expect(page).to have_selector('tbody tr', count: 5)

    within(:css, '#count') do
      expect(page).to have_content '5'
    end
  end
end
