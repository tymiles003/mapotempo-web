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
