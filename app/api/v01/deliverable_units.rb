# Copyright © Mapotempo, 2016
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

class V01::DeliverableUnits < Grape::API
  helpers SharedParams
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def deliverable_unit_params
      p = ActionController::Parameters.new(params)
      p = p[:deliverable_unit] if p.key?(:deliverable_unit)
      p.permit(:label, :default_quantity, :optimization_overload_multiplier)
    end
  end

  resource :deliverable_units do
    desc 'Fetch customer\'s deliverable units. At least one deliverable unit exists per customer.',
      nickname: 'getDeliverableUnits',
      is_array: true,
      entity: V01::Entities::DeliverableUnit
    params do
      optional :ids, type: Array[Integer], desc: 'Select returned deliverable units by id.', coerce_with: CoerceArrayInteger
    end
    get do
      deliverable_units = if params.key?(:ids)
        current_customer.deliverable_units.select{ |deliverable_unit| params[:ids].include?(deliverable_unit.id) }
      else
        current_customer.deliverable_units.load
      end
      present deliverable_units, with: V01::Entities::DeliverableUnit
    end

    desc 'Fetch deliverable unit.',
      nickname: 'getDeliverableUnit',
      entity: V01::Entities::DeliverableUnit
    params do
      requires :id, type: Integer
    end
    get ':id' do
      present current_customer.deliverable_units.find(params[:id]), with: V01::Entities::DeliverableUnit
    end

    desc 'Create deliverable unit.',
      detail: '(Note a default deliverable unit is already automatically created with a customer.) By creating a new deliverable unit, it will be possible to specify quantities and capacities for this another unit.',
      nickname: 'createDeliverableUnit',
      entity: V01::Entities::DeliverableUnit
    params do
      use :params_from_entity, entity: V01::Entities::DeliverableUnit.documentation.except(:id)
    end
    post do
      deliverable_unit = current_customer.deliverable_units.build(deliverable_unit_params)
      deliverable_unit.save!
      present deliverable_unit, with: V01::Entities::DeliverableUnit
    end

    desc 'Update deliverable unit.',
      nickname: 'updateDeliverableUnit',
      entity: V01::Entities::DeliverableUnit
    params do
      requires :id, type: Integer
      use :params_from_entity, entity: V01::Entities::DeliverableUnit.documentation.except(:id)
    end
    put ':id' do
      deliverable_unit = current_customer.deliverable_units.find(params[:id])
      deliverable_unit.update! deliverable_unit_params
      present deliverable_unit, with: V01::Entities::DeliverableUnit
    end

    desc 'Delete deliverable unit.',
      nickname: 'deleteDeliverableUnit'
    params do
      requires :id, type: Integer
    end
    delete ':id' do
      current_customer.deliverable_units.find(params[:id]).destroy
    end

    desc 'Delete multiple deliverable units.',
      nickname: 'deleteDeliverableUnits'
    params do
      requires :ids, type: Array[Integer], coerce_with: CoerceArrayInteger
    end
    delete do
      DeliverableUnit.transaction do
        current_customer.deliverable_units.select{ |deliverable_unit| params[:ids].include?(deliverable_unit.id) }.each(&:destroy)
      end
    end
  end
end
