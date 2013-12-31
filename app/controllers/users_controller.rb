class UsersController < ApplicationController
  load_and_authorize_resource
  before_action :set_user, only: [:edit_settings, :update_settings]

  def edit_settings
  end

  def update_settings
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to edit_user_settings_path(@user), notice: t('activerecord.successful.messages.updated', model: @user.class.model_name.human) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:layer_id)
    end
end
