class V01::Plannings < Grape::API
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
    def planning_params
      p = ActionController::Parameters.new(params)
      p = p[:planning] if p.has_key?(:planning)
      p.permit(:name, :zoning_id, :tag_ids => [])
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

  resource :plannings do
    desc "Return customer's plannings."
    get do
      present current_customer.plannings.load, with: V01::Entities::Planning
    end

    desc "Return a planning."
    get ':id' do
      present current_customer.plannings.find(params[:id]), with: V01::Entities::Planning
    end

    desc "Create a planning.", {
      params: V01::Entities::Planning.documentation.except(:id)
    }
    post  do
      planning = current_customer.plannings.build(planning_params)
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc "Update a planning.", {
      params: V01::Entities::Planning.documentation.except(:id)
    }
    put ':id' do
      planning = current_customer.plannings.find(params[:id])
      planning.update(planning_params)
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc "Destroy a planning."
    delete ':id' do
      current_customer.plannings.find(params[:id]).destroy
    end

    desc "Move a stop between routes."
    patch ':id/move' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc "Force recompute the planning after parameter update."
    get ':id/refresh' do
      planning = current_customer.plannings.find(params[:id])
      planning.compute
      planning.save!
      present planning, with: V01::Entities::Planning
    end

    desc "Switch two vehicles."
    patch ':id/switch' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc "Suggest a place for an unaffected destination."
    patch ':id/automatic_insert' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc "Set stop status."
    patch ':id/update_stop' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc "Starts asynchronous route optimization."
    get ':id/optimize_route' do
      # TODO
      error!('501 Not Implemented', 501)
    end

    desc "Clone the planning."
    patch ':id/duplicate' do
      planning = current_customer.plannings.find(params[:id])
      planning = planning.amoeba_dup
      planning.save!
      present planning, with: V01::Entities::Planning
    end
  end
end
