# Copyright © Mapotempo, 2013-2014
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
class TagsController < ApplicationController
  load_and_authorize_resource except: :create
  before_action :set_tag, only: [:edit, :update, :destroy]

  def index
    @tags = current_user.customer.tags
  end

  def new
    @tag = current_user.customer.tags.build
  end

  def edit
  end

  def create
    @tag = current_user.customer.tags.build(tag_params)

    respond_to do |format|
      if @tag.save
        format.html { redirect_to tags_path, notice: t('activerecord.successful.messages.created', model: @tag.class.model_name.human) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to tags_path, notice: t('activerecord.successful.messages.updated', model: @tag.class.model_name.human) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @tag.destroy
    respond_to do |format|
      format.html { redirect_to tags_url }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tag
    @tag = Tag.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def tag_params
    params.require(:tag).permit(:label, :color, :icon)
  end
end
