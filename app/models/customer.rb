# Copyright © Mapotempo, 2013-2016
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
require 'sanitize'

class Customer < ActiveRecord::Base
  belongs_to :reseller
  belongs_to :profile
  belongs_to :router
  belongs_to :job_destination_geocoding, class_name: 'Delayed::Backend::ActiveRecord::Job', dependent: :destroy
  belongs_to :job_store_geocoding, class_name: 'Delayed::Backend::ActiveRecord::Job', dependent: :destroy
  belongs_to :job_optimizer, class_name: 'Delayed::Backend::ActiveRecord::Job', dependent: :destroy
  has_many :products, -> { order('code') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :plannings, -> { includes(:tags).order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :order_arrays, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :zonings, inverse_of: :customer, dependent: :delete_all
  before_destroy :destroy_disable_vehicle_usage_sets_validation # Declare and run before has_many :vehicle_usage_sets
  has_many :vehicle_usage_sets, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :destroy
  has_many :vehicles, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :stores, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :destinations, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :tags, -> { order('label') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :users, inverse_of: :customer, dependent: :destroy
  enum router_dimension: Router::DIMENSION

  nilify_blanks
  auto_strip_attributes :name, :tomtom_account, :tomtom_user, :tomtom_password, :print_header, :masternaut_user, :masternaut_password, :alyacom_association, :default_country
  validates :profile, presence: true
  validates :router, presence: true
  validates :router_dimension, presence: true
  validates :name, presence: true
  validates :default_country, presence: true
  validates :stores, length: { maximum: Mapotempo::Application.config.max_destinations / 10, message: :over_max_limit }
  validates :destinations, length: { maximum: Mapotempo::Application.config.max_destinations, message: :over_max_limit }
  validates :optimization_cluster_size, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_vehicles, numericality: { greater_than: 0 }
  validate do
    errors.add(:max_vehicles, :not_an_integer) if @invalid_max_vehicle
    !@invalid_max_vehicle
  end
  validates :speed_multiplicator, numericality: { greater_than_or_equal_to: 0.5, less_than_or_equal_to: 1.5 }, if: :speed_multiplicator

  after_initialize :assign_defaults, :update_max_vehicles, if: 'new_record?'
  after_create :create_default_store, :create_default_vehicle_usage_set
  before_update :update_out_of_date, :update_max_vehicles, :update_enable_multi_visits
  before_save :sanitize_print_header
  before_save :devices_update_vehicles, prepend: true

  include RefSanitizer

  amoeba do
    enable
    exclude_association :plannings
    exclude_association :routes
    exclude_association :stores
    exclude_association :users
    exclude_association :vehicle_usage_sets
    exclude_association :vehicle_usages
    exclude_association :vehicles
    exclude_association :zonings
    customize(lambda { |original, copy|
      copy.name += " (%s)" % [I18n.l(Time.now, format: :long)]

      copy.attributes.select{|attr| attr[/job_/] }.keys.each do |name|
        copy.send "#{name}=", nil
      end

      original.stores.each do |store|
        dup_store = copy.stores.new store.attributes.reject{|attr| attr[/id/] }
        dup_store.customer = copy
      end

      original.vehicle_usage_sets.each do |vehicle_usage_set|
        dup_vehicle_usage_set = copy.vehicle_usage_sets.new vehicle_usage_set.attributes.reject{|attr| attr[/id/] }
        dup_vehicle_usage_set.customer = copy
      end

      original.vehicles.each do |vehicle|
        dup_vehicle = copy.vehicles.new vehicle.attributes.reject{|attr| attr[/id/] }
        dup_vehicle.customer = copy
      end

      original.vehicle_usage_sets.each do |vehicle_usage_set|
        vehicle_usage_set.vehicle_usages.each do |vehicle_usage|
          dup_vehicle_usage = VehicleUsage.new vehicle_usage.attributes.reject{|attr| attr[/id/] }
          dup_vehicle_usage.vehicle_usage_set = copy.vehicle_usage_sets.detect{|item| item.name == vehicle_usage.vehicle_usage_set.name }
          dup_vehicle_usage.vehicle = copy.vehicles.detect{|item| item.name == vehicle_usage.vehicle.name }
          [:store_start, :store_stop, :store_rest].each do |attr|
            next if !vehicle_usage.send(attr)
            dup_vehicle_usage.send "#{attr}=", copy.stores.detect{|item| item.name == vehicle_usage.send(attr).name }
          end
        end
      end

      original.zonings.each do |zoning|
        dup_zoning = copy.zonings.new zoning.attributes.reject{|attr| attr[/id/] }
        zoning.zones.each do |zone|
          dup_zone = Zone.new zone.attributes.reject{|attr| attr[/id/] }
          dup_zone.vehicle = copy.vehicles.detect{|item| item.name == zone.vehicle.name } if zone.vehicle
          dup_zoning.zones << dup_zone
        end
        dup_zoning.customer = copy
      end

      original.users.each do |user|
        dup_user = copy.users.new
        if user.email =~ /duplicate/
          dup_user.email = Time.now.to_i.to_s + "@example.com"
        else
          dup_user.email = user.email.split("@")[0] + "+duplicate@" + user.email.split("@")[1]
        end
        dup_user.password = user.password_confirmation = Time.now.to_i * rand(100)
        dup_user.customer = copy
      end

      Customer.skip_callback :create, :after, :create_default_store
      Customer.skip_callback :create, :after, :create_default_vehicle_usage_set

      copy.save!

      Planning.skip_callback :create, :before, :default_routes
      Planning.skip_callback :create, :before, :update_zonings
      Planning.skip_callback :save, :before, :update_zonings
      Planning.skip_callback :save, :before, :update_vehicle_usage_set

      original.plannings.each do |planning|
        dup_planning = copy.plannings.new planning.attributes.slice("name")
        dup_planning.vehicle_usage_set = copy.vehicle_usage_sets.detect{|item| item.name == planning.vehicle_usage_set.name }
        planning.zonings.each{|zoning| dup_planning.zonings << copy.zonings.detect{|item| item.name == zoning.name } }
        planning.routes.each do |route|
          dup_route = dup_planning.routes.new route.attributes.reject{|attr| attr[/id/] }
          next if !route.vehicle_usage
          dup_route.vehicle_usage = dup_planning.vehicle_usage_set.vehicle_usages.detect{|item| item.vehicle.name == route.vehicle_usage.vehicle.name }
        end
        dup_planning.customer = copy
        dup_planning.save!

      end

    })
  end

  def duplicate
    self.amoeba_dup
  end

  def default_position
    store = stores.find{ |s| !s.lat.nil? && !s.lng.nil? }
    # store ? [store.lat, store.lng] : [I18n.t('stores.default.lat'), I18n.t('stores.default.lng')]
    {lat: store ? store.lat : I18n.t('stores.default.lat'), lng: store ? store.lng : I18n.t('stores.default.lng')}
  end

  def max_vehicles
    @max_vehicles = @max_vehicles || vehicles.size
  end

  def max_vehicles=(max)
    begin
      if !max.blank?
        @max_vehicles = Integer(max.to_s, 10)
      end
    rescue ArgumentError
      @invalid_max_vehicle = true
    end
  end

  def masternaut?
    enable_masternaut && !masternaut_user.blank? && !masternaut_password.blank?
  end

  def alyacom?
    enable_alyacom && !alyacom_association.blank?
  end

  def tomtom?
    enable_tomtom && !tomtom_account.blank? && !tomtom_user.blank? && !tomtom_password.blank?
  end

  def teksat?
    enable_teksat && !teksat_customer_id.blank? && !teksat_url.blank? && !teksat_username.blank? && !teksat_password.blank?
  end

  def orange?
    enable_orange && !orange_user.blank? && !orange_password.blank?
  end

  def visits
    destinations.collect{ |destination| destination.visits }.flatten
  end

  def delete_all_destinations
    destinations.delete_all
    plannings.each { |p|
      p.routes.select(&:vehicle_usage).each do |route|
        # reindex remaining stops (like rests)
        route.force_reindex
        # out_of_date for last step
        route.out_of_date = true if route.stop_trace
      end
      p.save!
    }
  end

  private

  def devices_update_vehicles
    self.vehicles.select(&:tomtom_id).each{|vehicle| vehicle.tomtom_id = nil } if (self.tomtom_account_changed? && !self.tomtom_account_was.nil?) || (self.tomtom_user_changed? && !self.tomtom_user_was.nil?)
    self.vehicles.select(&:teksat_id).each{|vehicle| vehicle.teksat_id = nil } if (self.teksat_customer_id_changed? && !self.teksat_customer_id_was.nil?) || (self.teksat_username_changed? && !self.teksat_username_was.nil?)
    self.vehicles.select(&:orange_id).each{|vehicle| vehicle.orange_id = nil } if self.orange_user_changed? && !self.orange_user_was.nil?
  end

  def assign_defaults
    self.default_country ||= I18n.t('customers.default.country')
    self.enable_references = Mapotempo::Application.config.enable_references
    self.enable_multi_visits = Mapotempo::Application.config.enable_multi_visits
  end

  def create_default_store
    stores.create(
      name: I18n.t('stores.default.name'),
      city: I18n.t('stores.default.city'),
      lat: Float(I18n.t('stores.default.lat')),
      lng: Float(I18n.t('stores.default.lng'))
    )
  end

  def create_default_vehicle_usage_set
    vehicle_usage_sets.create(
      name: I18n.t('vehicle_usage_sets.default.name'),
      store_start: stores[0],
      store_stop: stores[0]
    )
  end

  def update_out_of_date
    if take_over_changed? || router_id_changed? || router_dimension_changed? || speed_multiplicator_changed?
      Route.transaction do
        plannings.each{ |planning|
          planning.routes.each{ |route|
            route.out_of_date = true
          }
        }
      end
    end
  end

  def update_max_vehicles
    if max_vehicles != vehicles.size
      if vehicles.size < max_vehicles
        # Add new
        (max_vehicles - vehicles.size).times{ |_i|
          vehicle = vehicles.build(name: I18n.t('vehicles.default_name', n: vehicles.size + 1))
          vehicle.color = Vehicle.colors_table[(vehicles.size - 1) % Vehicle.colors_table.size]
        }
      elsif vehicles.size > max_vehicles
        # Delete
        (vehicles.size - max_vehicles).times{ |i|
          vehicle = vehicles[vehicles.size - 1]
          vehicles.destroy(vehicle)
        }
      end
      @max_vehicles = vehicles.size
    end
  end

  def update_enable_multi_visits
    if enable_multi_visits_changed?
      Destination.transaction do
        if enable_multi_visits
          self.destinations.each{ |destination|
            destination.visits.each{ |visit|
              visit.ref = destination.ref
              visit.tags = destination.tags # ?
            }
            destination.ref = nil
            destination.tag_ids = []
          }
        else
          self.destinations.each{ |destination|
            if destination.visits.size > 0
              destination.ref = destination.visits[0].ref
              destination.tags = destination.visits[0].tags # ?
              destination.visits.each{ |visit|
                visit.ref = nil
                visit.tag_ids = []
              }
            end
          }
        end
      end
    end
  end

  def sanitize_print_header
    self.print_header = Sanitize.fragment(print_header, Sanitize::Config::RELAXED)
  end

  def destroy_disable_vehicle_usage_sets_validation
    vehicle_usage_sets.each{ |vehicle_usage_set|
      def vehicle_usage_set.destroy_vehicle_usage_set
        # Avoid validation of at least one vehicle_usage_set by customer
      end
    }
  end
end
