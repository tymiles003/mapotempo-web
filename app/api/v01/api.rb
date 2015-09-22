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
require 'parse_ids_refs'

class V01::CoerceArrayInteger
  def self.parse(s)
    s.split(',').collect{ |i| Integer(i) }
  end
end

class V01::Api < Grape::API
  helpers do
    def warden
      env['warden']
    end

    def current_customer(customer_id = nil)
      params = Rack::Utils.parse_nested_query(request.query_string)
      @current_user ||= warden.authenticated? && warden.user
      @current_user ||= params['api_key'] && User.find_by(api_key: params['api_key'])
      @current_customer ||= @current_user && (@current_user.admin? && customer_id ? @current_user.reseller.customers.find(Integer(customer_id)) : @current_user.customer)
    end

    def authenticate!
      current_customer
      error!('401 Unauthorized', 401) unless @current_user
      error!('402 Payment Required', 402) if @current_customer && @current_customer.end_subscription && @current_customer.end_subscription < Time.now
    end

    def authorize!
    end

    def error!(*args)
      # Workaround for close transaction on error!
      if !ActiveRecord::Base.connection.transaction_manager.current_transaction.is_a?(ActiveRecord::ConnectionAdapters::NullTransaction)
        ActiveRecord::Base.connection.transaction_open? and ActiveRecord::Base.connection.rollback_transaction
      end
      super.error!(*args)
    end
  end

  before do
    authenticate!
    authorize!
    ActiveRecord::Base.connection.transaction_open? and ActiveRecord::Base.connection.begin_transaction
  end

  after do
    begin
      if @error
        ActiveRecord::Base.connection.transaction_open? and ActiveRecord::Base.connection.rollback_transaction
      else
        ActiveRecord::Base.connection.transaction_open? and ActiveRecord::Base.connection.commit_transaction
      end
    rescue Exception
      ActiveRecord::Base.connection.transaction_open? and ActiveRecord::Base.connection.rollback_transaction
      raise
    end
  end

  rescue_from :all do |e|
    ActiveRecord::Base.connection.transaction_open? and ActiveRecord::Base.connection.rollback_transaction
    if e.is_a?(ActiveRecord::RecordNotFound)
      rack_response(nil, 404)
    elsif e.is_a?(ActiveRecord::RecordInvalid)
      rack_response({error: e.to_s}.to_json, 400)
    end
    @error = e
    Rails.logger.error "\n\n#{e.class} (#{e.message}):\n    " + e.backtrace.join("\n    ") + "\n\n"
    response = {message: e.message}
    if ENV['RAILS_ENV'] == 'test'
      response[:backtrace] = e.backtrace[0..10].join("\n    ")
    end
    rack_response(response.to_json, 500)
  end

  mount Customers
  mount Destinations
  mount Layers
  mount OrderArrays
  mount Orders
  mount Plannings
  mount Products
  mount Profiles
  mount Routers
  mount Routes
  mount Stops
  mount Stores
  mount Tags
  mount Users
  mount Vehicles
  mount Zonings

  # Tools
  mount Geocoder
end
