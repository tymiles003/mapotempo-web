class V01::Stores < Grape::API
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
    def store_params
      p = ActionController::Parameters.new(params)
      p = p[:store] if p.has_key?(:store)
      p.permit(:name, :street, :postalcode, :city, :lat, :lng, :open, :close)
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

  resource :stores do
    desc "Return customer's stores."
    get do
      present current_customer.stores.load, with: V01::Entities::Store
    end

    desc "Return a store."
    get ':id' do
      present current_customer.stores.find(params[:id]), with: V01::Entities::Store
    end

    desc "Create a store.", {
      params: V01::Entities::Store.documentation.except(:id)
    }
    post  do
      store = current_customer.stores.build(store_params)
      current_customer.save!
      present store, with: V01::Entities::Store
    end

    desc "Update a store.", {
      params: V01::Entities::Store.documentation.except(:id)
    }
    put ':id' do
      store = current_customer.stores.find(params[:id])
      store.assign_attributes(store_params)
      store.reverse_geocode if params.has_key?(:reverse)
      store.save!
      store.customer.save! if store.customer
      present store, with: V01::Entities::Store
    end

    desc "Destroy a store."
    delete ':id' do
      current_customer.stores.find(params[:id]).destroy
    end

    desc "Geocode a store.", {
      params: V01::Entities::Store.documentation.except(:id)
    }
    patch 'geocode' do
      store = Store.new(store_params)
      store.geocode
      present store, with: V01::Entities::Store
    end

    desc "Reverse geocode a store.", {
      params: V01::Entities::Store.documentation.except(:id)
    }
    patch 'geocode_reverse' do
      store = Store.new(store_params)
      store.reverse_geocode
      present store, with: V01::Entities::Store
    end

    if Mapotempo::Application.config.geocode_complete
      desc "Auto completion on store.", {
        params: V01::Entities::Store.documentation.except(:id)
      }
      patch 'geocode_complete' do
        p = store_params
        address_list = Geocode.complete(current_customer.stores[0].lat, current_customer.stores[0].lng, 40000, p[:street], p[:postalcode], p[:city])
        address_list = address_list.collect{ |i| {street: i[0], postalcode: i[1], city: i[2]} }
        address_list
      end
    end
  end
end
