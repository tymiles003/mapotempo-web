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
        (params.key?("live") and params["live"] == "true") or (@destination.save and current_user.save) # No save in "live" mode
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

  def export
    csv = CSV.generate { |csv|
      csv << [:name, :street, :postalcode, :city, :lat, :lng, :quantity, :open, :close]
      Destination.where(customer_id: current_user.customer.id).each { |destination|
        csv << [destination.name, destination.street, destination.postalcode, destination.city, destination.lat, destination.lng, destination.quantity, destination.open, destination.close]
      }
    }
    send_data csv, type: 'text/csv'
  end

  def upload
    file = params[:upload][:datafile].tempfile
    name = params[:upload][:datafile].original_filename.split('.')[0..-2].join('.')

    respond_to do |format|
      if Importer.import(current_user.customer, file, name) and current_user.save
        format.html { redirect_to :action => 'index' }
        format.json { render action: 'show', status: :created, location: @destination }
      else
        format.html { render action: 'import' }
        format.json { render json: current_user.errors, status: :unprocessable_entity }
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
