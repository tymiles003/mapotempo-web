Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 3
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

Delayed::Worker.class_eval do
  alias_method :run_was, :run
  def run(job)
    Customer.transaction isolation: :read_committed do
      run_was job
    end
  end
end
