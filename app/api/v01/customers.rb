class V01::Customers < Grape::API
  version '0.1', using: :path

  helpers do
    def current_customer
      @current_user ||= params[:api_key] && User.find_by(api_key: params[:api_key])
      @current_customer ||= @current_user && @current_user.customer
    end

    def authenticate!
      error!('401 Unauthorized', 401) unless current_customer
      error!('402 Payment Required', 402) if @current_customer.end_subscription && @current_customer.end_subscription > Time.now
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      p = ActionController::Parameters.new(params)
      p = p[:customer] if p.has_key?(:customer)
      if @current_user.admin?
        p.permit(:name, :end_subscription, :max_vehicles, :take_over, :print_planning_annotating, :tomtom_account, :tomtom_user, :tomtom_password, :router_id)
      else
        p.permit(:take_over, :print_planning_annotating, :tomtom_account, :tomtom_user, :tomtom_password)
      end
    end
  end

  before do
    authenticate!
    ActiveRecord::Base.connection.begin_transaction
  end

  after do
    begin
      ActiveRecord::Base.connection.commit_transaction unless @error
    rescue Exception
      ActiveRecord::Base.connection.rollback_transaction
      raise
    end
  end

  rescue_from :all do |e|
    @error = e
    Rails::logger.error "\n\n#{e.class} (#{e.message}):\n    " + e.backtrace.join("\n    ") + "\n\n"
    error_response({message: e.message})
  end

  resource :customers do
    desc "Return a customer."
    get do
      present current_customer, with: V01::Entities::Customer
    end

    desc "Update a customer.", {
      params: V01::Entities::Customer.documentation.except(:id)
    }
    put do
      current_customer.update(customer_params)
      current_customer.save!
      present current_customer, with: V01::Entities::Customer
    end

    desc "Cancel matrix computation"
    delete 'job_matrix' do
      if current_customer.job_matrix
        current_customer.job_matrix.destroy
      end
    end

    desc "Cancel optimization computation"
    delete 'job_optimizer' do
      if current_customer.job_optimizer
        current_customer.job_optimizer.destroy
      end
    end

    desc "Cancel optimization computation"
    delete 'job_geocoding' do
      if current_customer.job_geocoding
        current_customer.job_geocoding.destroy
      end
    end
  end
end
