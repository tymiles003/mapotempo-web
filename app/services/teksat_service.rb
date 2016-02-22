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
class TeksatService

  require "addressable"

  attr_reader :customer, :route, :ticket_id, :cache_object

  def initialize params
    @cache_object = ActiveSupport::Cache::FileStore.new(File.join(Dir.tmpdir, 'devices'), namespace: 'teksat', expires_in: 30)
    @customer = params[:customer]
    @route = params[:route]
    @ticket_id = params[:ticket_id]
  end

  def auth url, customer_id, username, password
    if url =~ /\A(www.*.teksat.fr)\Z/
      response = RestClient.get get_ticket_url(url, customer_id, username, password)
    else
      raise DeviceServiceError.new("Teksat: %s" % [ I18n.t('errors.teksat.bad_url') ])
    end
    if response.code == 200 && response.strip.length >= 1
      return response.strip
    else
      raise DeviceServiceError.new("Teksat: %s" % [ I18n.t('errors.teksat.get_ticket') ])
    end
  end

  def list
    with_cache "%s_%s" % [:list, customer.id] do
      response = RestClient.get get_vehicles_url
      if response.code == 200
        Nokogiri::XML(response).xpath("//vehicle").map do |item|
          { id: item["id"], text: "%s %s - %s" % [ item["brand"], item["type"], item["code"] ] }
        end
      else
        raise DeviceServiceError.new("Teksat: %s" % [ I18n.t('errors.teksat.list') ])
      end
    end
  end

  def send_route
    send_mission route, route.start, route.vehicle_usage.default_store_start.lat, route.vehicle_usage.default_store_start.lng
    route.stops.select(&:active?).select(&:position?).sort_by(&:index).each{|stop| send_mission(route, stop.time, stop.lat, stop.lng) }
    send_mission route, route.end, route.vehicle_usage.default_store_stop.lat, route.vehicle_usage.default_store_stop.lng
  end

  def clear_route
    response = RestClient.get get_missions_url(date: planning_date(route).strftime("%Y-%m-%d"))
    Nokogiri::XML(response).xpath("//mission").map{|item| RestClient.get(delete_mission_url(mi_id: item["id"])) }
  end

  def get_vehicles_pos
    with_cache "%s_%s" % [:get_vehicles_pos, customer.id] do
      response = RestClient.get get_vehicles_pos_url
      if response.code == 200
        Nokogiri::XML(response).xpath("//vehicle_pos").map do |item|
          { teksat_vehicle_id: item["v_id"], lat: item["lat"], lng: item["lng"], speed: item["speed"], time: item["data_time"], device_name: item["code"] }
        end
      else
        raise DeviceServiceError.new("Teksat: %s" % [ I18n.t('errors.teksat.get_vehicles_pos') ])
      end
    end
  end

  private

  def with_cache key, &block
    result = cache_object.read key
    return result if result
    result = yield
    cache_object.write key, result
    return result
  end

  def send_mission route, start_time, lat, lng
    route_params = {
      mi_v_id: route.vehicle_usage.vehicle.teksat_id,
      mi_label: route.planning.name,
      mi_customer: route.planning.customer.name
    }
    response = RestClient.get set_mission_url(route_params.merge(
      mi_begin_date: p_time(planning_date(route), start_time).strftime("%Y-%m-%d"),
      mi_begin_time: p_time(planning_date(route), start_time).strftime("%H-%M-%S"),
      mi_begin_latitude: lat,
      mi_begin_longitude: lng
    ))
    if response.code != 200
      raise DeviceServiceError.new("Teksat: %s" % [ I18n.t('errors.teksat.set_mission') ])
    end
  end

  def planning_date route
    route.planning.date ? route.planning.date.to_time : Time.now
  end

  def p_time route_date, time
    route_date + (time -  Time.new(2000, 1, 1, 0, 0, 0, '+00:00'))
  end

  def get_ticket_url url, customer_id, username, password
    Addressable::Template.new("http://%s/webservices/map/get-ticket.jsp{?query*}" % [ url ]).expand(
      query: { custID: customer_id, username: username, pw: password }
    ).to_s
  end

  def get_vehicles_url
    Addressable::Template.new("http://%s/webservices/map/get-vehicles.jsp{?query*}" % [ customer.teksat_url ]).expand(
      query: { custID: customer.teksat_customer_id, tck: ticket_id }
    ).to_s
  end

  def get_vehicles_pos_url
    Addressable::Template.new("http://%s/webservices/map/get-vehicles-pos.jsp{?query*}" % [ customer.teksat_url ]).expand(
      query: { custID: customer.teksat_customer_id, tck: ticket_id }
    ).to_s
  end

  def set_mission_url options
    Addressable::Template.new("http://%s/webservices/map/set-mission.jsp{?query*}" % [ customer.teksat_url ]).expand(
      query: options.merge(custID: customer.teksat_customer_id, tck: ticket_id)
    ).to_s
  end

  def get_missions_url options
    Addressable::Template.new("http://%s/webservices/map/get-missions.jsp{?query*}" % [ customer.teksat_url ]).expand(
      query: options.merge(custID: customer.teksat_customer_id, tck: ticket_id)
    ).to_s
  end

  def delete_mission_url options
    Addressable::Template.new("http://%s/webservices/map/delete-mission.jsp{?query*}" % [ customer.teksat_url ]).expand(
      query: options.merge(custID: customer.teksat_customer_id, tck: ticket_id)
    ).to_s
  end
end
