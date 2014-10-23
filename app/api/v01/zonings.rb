class V01::Zonings < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def zoning_params
      p = ActionController::Parameters.new(params)
      p = p[:zoning] if p.has_key?(:zoning)
      p.permit(:name, zones_attributes: [:id, :polygon, :_destroy, vehicle_ids: []])
    end
  end

  resource :zonings do
    desc "Return customer's zonings."
    get do
      present current_customer.zonings.load, with: V01::Entities::Zoning
    end

    desc "Return a zoning."
    get ':id' do
      present current_customer.zonings.find(params[:id]), with: V01::Entities::Zoning
    end

    desc "Create a zoning.", {
      params: V01::Entities::Zoning.documentation.except(:id)
    }
    post  do
      zoning = current_customer.zonings.build(zoning_params)
      zoning.save!
      present zoning, with: V01::Entities::Zoning
    end

    desc "Update a zoning.", {
      params: V01::Entities::Zoning.documentation.except(:id)
    }
    put ':id' do
      zoning = current_customer.zonings.find(params[:id])
      zoning.update(zoning_params)
      zoning.save!
      present zoning, with: V01::Entities::Zoning
    end

    desc "Destroy a zoning."
    delete ':id' do
      current_customer.zonings.find(params[:id]).destroy
    end
  end
end
