require 'test_helper'

class ImportTest < ActionDispatch::IntegrationTest
  setup do
    DatabaseCleaner.clean
    Capybara.reset!
    login
  end

  test 'import' do
    visit destination_import_path
    if Capybara.javascript_driver == :webkit
      evaluate_script("$('#destinations_import_model_file').attr('style','')") # capybara-webkit workaround
    end
    attach_file 'destinations_import_model[file]', Rails.root.join("test/fixtures/files/import_many-utf-8.csv")
    check 'destinations_import_model[replace]'
    submit

    first 'tbody tr'
    assert_selector 'tbody tr', count: 5

    within(:css, '#count') do
        assert_text '5'
    end
  end
end
