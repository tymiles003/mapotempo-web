require 'csv'
require 'importer'

class DestinationsController < ApplicationController
  load_and_authorize_resource :except => [:create, :upload]
  before_action :set_destination, only: [:show, :edit, :update, :destroy, :geocode_reverse, :geocode_complete, :geocode_code]

  # GET /destinations
  # GET /destinations.json
  def index
    @destinations = Destination.where(customer_id: current_user.customer.id)
    @tags = current_user.customer.tags
  end

  # GET /destinations/1
  # GET /destinations/1.json
  def show
  end

  # GET /destinations/new
  def new
    @destination = current_user.customer.store.dup
    @destination.name = ""
  end

  # GET /destinations/1/edit
  def edit
  end

  # POST /destinations
  # POST /destinations.json
  def create
    @destination = Destination.new(destination_params)
    @destination.customer = current_user.customer
    current_user.customer.destinations << @destination
    current_user.customer.plannings.each { |planning|
      planning.destination_add(@destination)
    }

    respond_to do |format|
      if current_user.save
        format.html { redirect_to @destination, notice: t('activerecord.successful.messages.created', model: @destination.class.model_name.human) }
        format.json { render action: 'show', status: :created, location: @destination }
      else
        format.html { render action: 'new' }
        format.json { render json: @destination.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /destinations/1
  # PATCH/PUT /destinations/1.json
  def update
    p = destination_params

    params[:tags] = params[:tags] || []
    if @destination.tag_ids.sort != params[:tags].collect{ |i| Integer(i) }.sort
      @destination.tags = current_user.customer.tags.select{ |tag| params[:tags].include?(String(tag.id)) }
    end

    respond_to do |format|
      ok = if @destination == current_user.customer.store
        @destination.assign_attributes(p)
        if params.key?("live") and params["live"] == "true" # No save in "live" mode
          if params.key?("live_type")
            if params["live_type"] == "address"
              @destination.geocode
            else
              @destination.reverse_geocode
            end
          end
        else
          @destination.save and current_user.save
        end
      else
        @destination.update(p) and current_user.save
      end
      if ok
        format.html { redirect_to edit_destination_path(@destination), notice: t('activerecord.successful.messages.updated', model: @destination.class.model_name.human) }
        format.json { render action: 'show', location: @destination }
      else
        format.html { render action: 'edit' }
        format.json { render json: @destination.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /destinations/1
  # DELETE /destinations/1.json
  def destroy
    @destination.destroy
    respond_to do |format|
      format.html { redirect_to destinations_url }
      format.json { head :no_content }
    end
  end

  def geocode_complete
    p = destination_params
    address_list = Geocode.complete(@destination.user.customer.store.lat, @destination.user.customer.store.lng, 40000, p[:street], p[:postalcode], p[:city])
    address_list = address_list.collect{ |i| {street: i[0], postalcode: i[1], city: i[2]} }
    respond_to do |format|
      format.html
      format.json { render json: address_list.to_json }
    end
  end

  def import
  end

  def upload
    replace = params[:replace]
    file = params[:upload][:datafile].tempfile
    name = params[:upload][:datafile].original_filename.split('.')[0..-2].join('.')

    respond_to do |format|
      begin
        Importer.import(replace, current_user.customer, file, name) and current_user.save
        format.html { redirect_to action: 'index' }
      rescue StandardError => e
        flash[:error] = e.message
        format.html { render action: 'import', status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_destination
      @destination = Destination.find(params[:id] || params[:destination_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def destination_params
      params.require(:destination).permit(:name, :street, :postalcode, :city, :lat, :lng, :quantity, :open, :close)
    end
end
