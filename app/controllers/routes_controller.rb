class RoutesController < ApplicationController
  load_and_authorize_resource
  before_action :set_route, only: [:update]

  def show
    respond_to do |format|
      format.html
      format.json { head :no_content }
      format.csv do
        response.headers['Content-Disposition'] = 'attachment; filename="'+@route.vehicle.name.gsub('"','')+'.csv"'
      end
    end
  end

  # PATCH/PUT /routes/1
  # PATCH/PUT /routes/1.json
  def update
    respond_to do |format|
      if @route.update(route_params)
        format.html { redirect_to @route, notice: t('activerecord.successful.messages.updated', model: @route.class.model_name.human) }
        format.json { head :no_content }
        format.csv do
          response.headers['Content-Disposition'] = 'attachment; filename="#{vehicle.name}.csv"'
        end
      else
        format.html { render action: 'edit' }
        format.json { render json: @route.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_route
      @route = Route.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def route_params
      params.require(:route).permit(:hidden, :locked)
    end
end
