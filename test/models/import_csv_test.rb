require 'test_helper'

class ImportCsvTest < ActiveSupport::TestCase
  setup do
    @importer = ImporterDestinations.new(customers(:customer_one))
  end

  test 'should upload' do
    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join('test/fixtures/files/import_stores_one.csv')),
    })
    file.original_filename = 'import_stores_one.csv'

    import_csv = ImportCsv.new(importer: @importer, replace: false, file: file)
    assert import_csv.valid?
  end

  test 'shoud import too many destinations' do
    importer_destinations = ImporterDestinations.new(@customer)
    def importer_destinations.max_lines
      2
    end

    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_many-utf-8.csv')),
    })
    file.original_filename = 'import_destinations_many-utf-8.csv'

    assert_difference('Destination.count', 0) do
      assert !ImportCsv.new(importer: importer_destinations, replace: false, file: file).import
    end
  end

  test 'shoud not import without file' do
    assert_difference('Destination.count', 0) do
      assert !ImportCsv.new(importer: @importer, replace: false, file: nil).import
    end
  end

  test 'shoud not import invalid' do
    file = ActionDispatch::Http::UploadedFile.new({
      tempfile: File.new(Rails.root.join('test/fixtures/files/import_invalid.csv')),
    })
    file.original_filename = 'import_invalid.csv'

    assert_difference('Destination.count', 0) do
      o = ImportCsv.new(importer: @importer, replace: false, file: file)
      assert !o.import
      assert o.errors[:base][0].match('ligne 2')
    end
  end
end
