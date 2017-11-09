require 'test_helper'

require 'benchmark'

class BenchmarkTest < ActionDispatch::IntegrationTest
  setup do
    Mapotempo::Application.config.max_destinations = 30_000

    # Disable logs
    dev_null = Logger.new('/dev/null')
    Rails.logger = dev_null
    ActiveRecord::Base.logger = dev_null

    @customer = customers(:customer_two)
    @customer.max_vehicles = 165
    @customer.job_optimizer_id = nil
    @customer.job_destination_geocoding_id = nil
    @customer.save!

    @user = @customer.users.first

    Delayed::Job.destroy_all

    @importer = ImporterDestinations.new(@customer)

    def @importer.max_lines
      30_000
    end

    def Job.on_planning(_job, _planning_id)
      false
    end

    Capybara.current_driver = :selenium_chrome

    sign_in(@user, scope: :user)
  end

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |_url, _mode, _dimension, segments, _options| segments.collect { |_| [1000, 60, '_ibE_seK_seK_seK'] } }) do
      yield
    end
  end

  if ENV['BENCHMARK'] == 'true'
    test 'shows a planning with 900 points in less than 30 seconds' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark_900.csv'))
                                                    })
      file.original_filename = 'import_destinations_benchmark_900.csv'
      import_csv = ImportCsv.new(importer: @importer, replace: false, file: file)
      assert import_csv.import

      # Planning imported is not yet fully created when visiting the page
      # @planning = Planning.last
      # Use the first which has no tags
      @planning = @customer.plannings.first

      @time_elapsed = Benchmark.realtime do
        visit edit_planning_path(@planning)

        assert_selector '.routes.ui-sortable'
        assert_no_selector 'body.ajax_waiting'
      end.round

      assert @time_elapsed <= 30
    end

    test 'shows a planning with 4 000 points in less than 30 seconds' do
      file = ActionDispatch::Http::UploadedFile.new({
                                                      tempfile: File.new(Rails.root.join('test/fixtures/files/import_destinations_benchmark_4000.csv'))
                                                    })
      file.original_filename = 'import_destinations_benchmark_4000.csv'
      import_csv = ImportCsv.new(importer: @importer, replace: false, file: file)
      assert import_csv.import

      # Planning imported is not yet fully created when visiting the page
      # @planning = Planning.last
      # Use the first which has no tags
      @planning = @customer.plannings.first

      @time_elapsed = Benchmark.realtime do
        visit edit_planning_path(@planning)

        assert_selector '.routes.ui-sortable'
        assert_no_selector 'body.ajax_waiting'
      end.round

      assert @time_elapsed <= 30
    end
  end
end
