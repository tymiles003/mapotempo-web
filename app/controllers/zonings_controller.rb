class ZoningsController < ApplicationController
  load_and_authorize_resource :except => :create
  before_action :set_zoning, only: [:show, :edit, :update, :destroy]

  # GET /zonings
  # GET /zonings.json
  def index
    @zonings = Zoning.where(customer_id: current_user.customer.id)
  end

  # GET /zonings/1
  # GET /zonings/1.json
  def show
  end

  # GET /zonings/new
  def new
    @zoning = Zoning.new
  end

  # GET /zonings/1/edit
  def edit
    @planning = params.key?(:planning_id) ? Planning.where(customer_id: current_user.customer.id, id: params[:planning_id]).first : nil
    respond_to do |format|
      format.html do
        js(
          zoning_id: @zoning.id,
          planning_id: @planning ? @planning.id : nil,
          map_layer_url: current_user.layer.url,
          map_lat: current_user.customer.store.lat,
          map_lng: current_user.customer.store.lng,
          map_attribution: t('all.osm_attribution_html', layer_attribution: current_user.layer.attribution),
          vehicles_array: current_user.customer.vehicles.collect{ |vehicle|
            {id: vehicle.id, name: vehicle.name, color: vehicle.color}
          },
          vehicles_map: Hash[current_user.customer.vehicles.collect{ |vehicle|
            [vehicle.id, {id: vehicle.id, name: vehicle.name, color: vehicle.color}]
          }]
        )
      end
      format.json
    end
  end

  # POST /zonings
  # POST /zonings.json
  def create
    @zoning = Zoning.new(zoning_params)
    @zoning.customer = current_user.customer

    respond_to do |format|
      if save_zoning
        format.html { redirect_to edit_zoning_path(@zoning), notice: t('activerecord.successful.messages.created', model: @zoning.class.model_name.human) }
        format.json { render action: 'show', status: :created, location: @zoning }
      else
        format.html { render action: 'new' }
        format.json { render json: @zoning.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /zonings/1
  # PATCH/PUT /zonings/1.json
  def update
    respond_to do |format|
      if save_zoning
        format.html { redirect_to edit_zoning_path(@zoning), notice: t('activerecord.successful.messages.updated', model: @zoning.class.model_name.human) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @zoning.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /zonings/1
  # DELETE /zonings/1.json
  def destroy
    @zoning.destroy
    respond_to do |format|
      format.html { redirect_to zonings_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_zoning
      @zoning = Zoning.find(params[:id] || params[:zoning_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def zoning_params
      params.require(:zoning).permit(:name)
    end

    def zoning_neasted_params
      params.require(:zoning).permit({zones: [:polygon, {vehicles: [:vehicle_id]}]})
    end

    def save_zoning
      znp = zoning_neasted_params['zones']
      if znp
        znp = znp.collect{ |zone|
          if zone['vehicles']
            zone['vehicles'] = zone['vehicles'].collect{ |vehicle|
              Vehicle.where(id: Integer(vehicle['vehicle_id']), customer: current_user.customer).first
            }.select{ |vehicle| vehicle }
          end
          zone
        }
      end

      @zoning.update_attributes(zoning_params) and @zoning.set_zones(znp) and @zoning.save
    end
end
