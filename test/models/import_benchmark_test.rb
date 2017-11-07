require 'test_helper'

require 'benchmark'

if ENV['BENCHMARK'] == 'true'
  class ImportBenchmarkTest < ActiveSupport::TestCase
    setup do
      # Disable logs
      dev_null = Logger.new('/dev/null')
      Rails.logger = dev_null
      ActiveRecord::Base.logger = dev_null

      @importer = ImporterDestinations.new(customers(:customer_one))

      def @importer.max_lines
        30_000
      end
    end

    test 'should upload 28 100 points with 165 vehicles in less than 35 minutes (BENCHMARK)' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark.csv'))
                                                    })
      file.original_filename = 'import_destinations_benchmark.csv'

      @time_elapsed = Benchmark.realtime do
        import_csv = ImportCsv.new(importer: @importer, replace: false, file: file)
        assert import_csv.valid?
        import_csv.import
      end.round

      assert @time_elapsed <= 35 * 60
    end
  end
end
