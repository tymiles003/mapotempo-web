# Copyright © Mapotempo, 2014-2015
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
require 'coerce'

class V01::Users < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      p = ActionController::Parameters.new(params)
      p = p[:user] if p.key?(:user)
      if @current_user.admin?
        p.permit(:ref, :email, :password, :customer_id, :layer_id, :url_click2call, :time_zone)
      else
        p.permit(:layer_id, :url_click2call, :time_zone)
      end
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'.freeze
  end

  resource :users do
    desc 'Fetch customer\'s users (or all users with an admin key).',
      nickname: 'getUsers',
      is_array: true,
      entity: V01::Entities::User
    get do
      if @current_user.admin?
        users = User.where(reseller: @current_user.reseller) +
          User.joins(:customer).where(customers: {reseller_id: @current_user.reseller.id})
      else
        users = @current_customer.users.load
      end
      present users, with: V01::Entities::User
    end

    desc 'Fetch user.',
      nickname: 'getUser',
      entity: V01::Entities::User
    params do
      requires :id, type: String, desc: ID_DESC
    end
    get ':id' do
      id = ParseIdsRefs.read(params[:id])
      if @current_user.admin?
        user = (User.where(id.merge(reseller: @current_user.reseller)) +
          User.joins(:customer).where(id.merge(customers: {reseller_id: @current_user.reseller.id}))).first
        if user
          present user, with: V01::Entities::User
        else
          status 404
        end
      else
        present @current_customer.users.where(id).first!, with: V01::Entities::User
      end
    end

    desc 'Create user.',
      detail: 'Only available with an admin api_key.',
      nickname: 'createUser',
      params: V01::Entities::User.documentation.except(:id).deep_merge(
        email: { required: true },
        password: { required: true },
        customer_id: { required: true },
        layer_id: { required: true }
      ),
      entity: V01::Entities::User
    post do
      if @current_user.admin?
        customer = @current_user.reseller.customers.where(id: params[:customer_id]).first!
        user = customer.users.build(user_params)
        user.password_confirmation = user.password
        user.save!
        present user, with: V01::Entities::User
      else
        error! 'Forbidden', 403
      end
    end

    desc 'Update user.',
      nickname: 'updateUser',
      params: V01::Entities::User.documentation.except(:id),
      entity: V01::Entities::User
    params do
      requires :id, type: String, desc: ID_DESC
    end
    put ':id' do
      id = ParseIdsRefs.read(params[:id])
      user = (User.where(id.merge(reseller: @current_user.reseller)) +
        User.joins(:customer).where(id.merge(customers: {reseller_id: @current_user.reseller_id}))).first
      user.update! user_params
      present user, with: V01::Entities::User
    end

    desc 'Delete user.',
      detail: 'Only available with an admin api_key.',
      nickname: 'deleteUser'
    params do
      requires :id, type: String, desc: ID_DESC
    end
    delete ':id' do
      if @current_user.admin?
        id = ParseIdsRefs.read(params[:id])
        user = (User.where(id.merge(reseller: @current_user.reseller)) +
          User.joins(:customer).where(id.merge(customers: {reseller_id: @current_user.reseller.id}))).first
        user.destroy!
      else
        error! 'Forbidden', 403
      end
    end

    desc 'Delete multiple users.',
      detail: 'Only available with an admin api_key.',
      nickname: 'deleteUsers'
    params do
      requires :ids, type: Array[String], desc: 'Ids separated by comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    delete do
      if @current_user.admin?
        User.transaction do
          (User.where(reseller: @current_user.reseller) +
            User.joins(:customer).where(customers: {reseller_id: @current_user.reseller.id})).select{ |user|
            params[:ids].any?{ |s| ParseIdsRefs.match(s, user) }
          }.each(&:destroy)
        end
      else
        error! 'Forbidden', 403
      end
    end

  end
end
