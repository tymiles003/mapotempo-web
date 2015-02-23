class V01::Stores < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def store_params
      p = ActionController::Parameters.new(params)
      p = p[:store] if p.key?(:store)
      p.permit(:name, :street, :postalcode, :city, :lat, :lng, :open, :close)
    end
  end

  resource :stores do
    desc "Return customer's stores."
    get do
      present current_customer.stores.load, with: V01::Entities::Store
    end

    desc 'Return a store.'
    get ':id' do
      present current_customer.stores.find(params[:id]), with: V01::Entities::Store
    end

    desc 'Create a store.', {
      params: V01::Entities::Store.documentation.except(:id)
    }
    post  do
      store = current_customer.stores.build(store_params)
      current_customer.save!
      present store, with: V01::Entities::Store
    end

    desc 'Update a store.', {
      params: V01::Entities::Store.documentation.except(:id)
    }
    put ':id' do
      store = current_customer.stores.find(params[:id])
      store.assign_attributes(store_params)
      store.save!
      store.customer.save! if store.customer
      present store, with: V01::Entities::Store
    end

    desc 'Destroy a store.'
    delete ':id' do
      current_customer.stores.find(params[:id]).destroy
    end

    desc 'Geocode a store.', {
      params: V01::Entities::Store.documentation.except(:id)
    }
    patch 'geocode' do
      store = Store.new(store_params)
      store.geocode
      present store, with: V01::Entities::Store
    end

    if Mapotempo::Application.config.geocode_complete
      desc 'Auto completion on store.', {
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
