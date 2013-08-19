#require 'geocode'
require 'csv'

class DestinationsController < ApplicationController
  load_and_authorize_resource :except => [:create, :upload]
  before_action :set_destination, only: [:show, :edit, :update, :destroy, :geocode_reverse, :geocode_complete, :geocode_code]

  # GET /destinations
  # GET /destinations.json
  def index
    @destinations = Destination.where(user_id: current_user.id)
    @tags = current_user.tags
  end

  # GET /destinations/1
  # GET /destinations/1.json
  def show
  end

  # GET /destinations/new
  def new
    @destination = current_user.store.dup
  end

  # GET /destinations/1/edit
  def edit
  end

  # POST /destinations
  # POST /destinations.json
  def create
    @destination = Destination.new(destination_params)
    @destination.user = current_user
    current_user.destinations << @destination
    current_user.plannings.each { |planning|
      planning.destination_add(@destination)
    }

    respond_to do |format|
      if current_user.save
        format.html { redirect_to @destination, notice: 'Destination was successfully created.' }
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
    p = update_data
    respond_to do |format|
      ok = if @destination == current_user.store
        @destination.assign_attributes(p)
        (params.key?("live") and params["live"] == "true") or (@destination.save and current_user.save) # No save in "live" mode
      else
        @destination.update(p) and @destination.save and current_user.save
      end
      if ok
        format.html { redirect_to edit_destination_path(@destination), notice: 'Destination was successfully updated.' }
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
    address_list = Geocode.complete(@destination.user.store.lat, @destination.user.store.lng, 40000, p[:street], p[:postalcode], p[:city])
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
      Destination.where(user_id: current_user.id).each { |destination|
        csv << [destination.name, destination.street, destination.postalcode, destination.city, destination.lat, destination.lng, destination.quantity, destination.open, destination.close]
      }
    }
    send_data csv, type: 'text/csv'
  end

  def upload
    tags = Hash[current_user.tags.collect{ |tag| [tag.label, tag] }]
    routes = Hash.new{ |h,k| h[k] = [] }

    separator = ','
    decimal = '.'
    File.open(params[:upload][:datafile].tempfile) do |f|
      line = f.readline
      splitComma, splitSemicolon = line.split(','), line.split(';')
      split, separator = splitComma.size() > splitSemicolon.size() ? [splitComma, ','] : [splitSemicolon, ';']

      csv = CSV.open(params[:upload][:datafile].tempfile, col_sep: separator, headers: true)
      row = csv.readline
      ilat = row.index('lat')
      row = csv.readline
      if ilat
        data = row[ilat]
        decimal = data.split('.').size > data.split(',').size ? '.' : ','
      end
    end

    Destination.transaction do
      current_user.destinations.destroy_all

      CSV.foreach(params[:upload][:datafile].tempfile, col_sep: separator, headers: true) { |row|
        r = row.to_hash.select{ |k|
          ["name", "street", "postalcode", "city", "lat", "lng"].include?(k)
        }
        if decimal == ','
          r["lat"].gsub!(',', '.')
          r["lng"].gsub!(',', '.')
        end
        destination = Destination.new(r)
        destination.user = current_user

        if row["tags"]
          destination.tags = row["tags"].split(',').collect { |key|
            if not tags.key?(key)
              current_user.tags << tags[key] = Tag.new(:label=>key, :user=>current_user)
            end
            tags[key]
          }
        end

        routes[row.key?("route")? row["route"] : nil] << destination

        if not(destination.lat and destination.lng)
#          address = Geocode.code(destination.street, destination.postalcode, destination.city)
          address = Geocoder.search([destination.street, destination.postalcode, destination.city, "FR"].join(','))
          if address and address.size >= 1
            destination.lat, destination.lng = address[0].latitude, address[0].longitude
#            address = address[0]
#            destination.lat = address["lat"]
#            destination.lng = address["lng"]
          end
        end

        current_user.destinations << destination
      }

      if routes.size > 1
        planning = Planning.new(name:params[:upload][:datafile].original_filename.split('.')[0..-2].join('.'))
        planning.user = current_user
        planning.set_destinations(routes.values)
        current_user.plannings << planning
     end
    end

    respond_to do |format|
      if current_user.save
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

  def update_data
    p = destination_params
    if p[:street] != @destination.street or p[:postalcode] != @destination.postalcode or p[:city] != @destination.city
      address = Geocoder.search([p[:street], p[:postalcode], p[:city], "France"].join(','))
#      address = Geocode.code(p[:street], p[:postalcode], p[:city])
      if address and address.size >= 1
        @destination.lat, @destination.lng = address[0].latitude, address[0].longitude
#        address = address[0]
#        @destination.lat, @destination.lng = address["lat"], address["lng"]
        p.delete(:lat)
        p.delete(:lng)
      end
    end

    if p[:lat] and p[:lng] and (Float(p[:lat]) != @destination.lat or Float(p[:lng]) != @destination.lng)
#        @destination.street, @destination.postalcode, @destination.city = Geocode.reverse(p[:lat], p[:lng])
      address = Geocoder.search([p[:lat], p[:lng]])
      # Google
      # @destination.street, @destination.postalcode, @destination.city = address[0].street_number+' '+address[0].route, address[0].postal_code, address[0].city
      # MapQuest
      @destination.street, @destination.postalcode, @destination.city = address[0].street, address[0].postal_code, address[0].city
      p.delete(:street)
      p.delete(:postalcode)
      p.delete(:city)
    end

    params[:tags] = params[:tags] || []
    if @destination.tag_ids.sort != params[:tags].collect{ |i| Integer(i) }.sort
      @destination.tags = current_user.tags.select{ |tag| params[:tags].include?(String(tag.id)) }
    end

    p
  end
end
