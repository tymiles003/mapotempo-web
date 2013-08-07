class UserController < ApplicationController
  load_and_authorize_resource
  before_action :set_user, only: [:edit, :update]

  def edit
  end

  def update
    respond_to do |format|
      p = user_params
      if @user.update(p)
        format.html { redirect_to user_edit_path(@user), notice: 'user was successfully updated.' }
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
      params.require(:user).permit(:display_map, :take_over, :layer_id)
    end
end
