class RemovePreviousOptionsToRouters < ActiveRecord::Migration
  def up
    # Save previous data
    previous_router_options = {}
    Router.all.order(:id).each do |router|
      previous_router_options[router.id] = {
          time: router.time,
          distance: router.distance,
          avoid_zones: router.avoid_zones,
          isochrone: router.isochrone,
          isodistance: router.isodistance
      }
    end

    remove_column :routers, :time
    remove_column :routers, :distance
    remove_column :routers, :avoid_zones
    remove_column :routers, :isochrone
    remove_column :routers, :isodistance

    # Restore data into new options column
    previous_router_options.each do |routerId, options|
      router = Router.find(routerId)
      router.options = {
          time: options[:time],
          distance: options[:distance],
          avoid_zones: options[:avoid_zones],
          isochrone: options[:isochrone],
          isodistance: options[:isodistance]
      }

      router.save!
    end
  end

  def down
    # Save previous data
    previous_router_options = {}
    Router.all.order(:id).each do |router|
      previous_router_options[router.id] = {
          time: router.options[:time],
          distance: router.options[:distance],
          avoid_zones: router.options[:avoid_zones],
          isochrone: router.options[:isochrone],
          isodistance: router.options[:isodistance]
      }
    end

    add_column :routers, :time, :boolean
    add_column :routers, :distance, :boolean
    add_column :routers, :avoid_zones, :boolean
    add_column :routers, :isochrone, :boolean
    add_column :routers, :isodistance, :boolean

    # Restore data into old columns
    previous_router_options.each do |routerId, options|
      router = Router.find(routerId)
      router.time = options[:time]
      router.distance = options[:distance]
      router.avoid_zones = options[:avoid_zones]
      router.isochrone = options[:isochrone]
      router.isodistance = options[:isodistance]
      router.save!
    end
  end
end
