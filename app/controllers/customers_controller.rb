class CustomersController < ApplicationController
  load_and_authorize_resource
  before_action :set_customer, only: [:edit, :update]

  def edit
  end

  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to edit_customer_path(@customer), notice: t('activerecord.successful.messages.cupdated', model: @customer.class.model_name.human) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer
      @customer = Customer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def customer_params
      params.require(:customer).permit(:take_over)
    end
end
