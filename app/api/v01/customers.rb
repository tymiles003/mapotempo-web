class V01::Customers < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      p = ActionController::Parameters.new(params)
      p = p[:customer] if p.has_key?(:customer)
      if @current_user.admin?
        p.permit(:name, :end_subscription, :max_vehicles, :take_over, :print_planning_annotating, :print_header, :tomtom_account, :tomtom_user, :tomtom_password, :router_id)
      else
        p.permit(:take_over, :print_planning_annotating, :print_header, :tomtom_account, :tomtom_user, :tomtom_password, :router_id)
      end
    end
  end

  resource :customers do
    desc "Return a customer."
    get ':id' do
      present current_customer(params[:id]), with: V01::Entities::Customer
    end

    desc "Update a customer.", {
      params: V01::Entities::Customer.documentation.except(:id)
    }
    put ':id' do
      current_customer(params[:id])
      @current_customer.update(customer_params)
      @current_customer.save!
      present @current_customer, with: V01::Entities::Customer
    end

    desc "Return a job"
    get ':id/job/:job_id' do
      current_customer(params[:id])
      if @current_customer.job_optimizer && @current_customer.job_optimizer_id = params[:job_id]
        @current_customer.job_optimizer
      elsif @current_customer.job_geocoding && @current_customer.job_geocoding_id = params[:job_id]
        @current_customer.job_geocoding
      end
    end

    desc "Cancel job"
    delete ':id/job/:job_id' do
      current_customer(params[:id])
      if @current_customer.job_optimizer && @current_customer.job_optimizer_id = params[:job_id]
        @current_customer.job_optimizer.destroy
      elsif @current_customer.job_geocoding && @current_customer.job_geocoding_id = params[:job_id]
        @current_customer.job_geocoding.destroy
      end
    end
  end
end
