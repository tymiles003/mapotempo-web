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
    @vehicles = @zoning.customer.vehicles
  end

  # GET /zonings/new
  def new
    @zoning = Zoning.new
  end

  # GET /zonings/1/edit
  def edit
  end

  # POST /zonings
  # POST /zonings.json
  def create
    @zoning = Zoning.new(zoning_params)
    @zoning.customer = current_user.customer

    respond_to do |format|
      if @zoning.save
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

      if @zoning.update_attributes(zoning_params) and @zoning.set_zones(znp) and @zoning.save
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
      @zoning = Zoning.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def zoning_params
      params.require(:zoning).permit(:name)
    end

    def zoning_neasted_params
      params.require(:zoning).permit({zones: [:polygon, {vehicles: [:vehicle_id]}]})
    end
end
