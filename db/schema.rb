# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20141028165002) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customers", force: true do |t|
    t.date     "end_subscription"
    t.integer  "max_vehicles"
    t.time     "take_over"
    t.integer  "job_geocoding_id"
    t.integer  "job_optimizer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "tomtom_account"
    t.string   "tomtom_user"
    t.string   "tomtom_password"
    t.integer  "router_id"
    t.boolean  "print_planning_annotating"
    t.text     "print_header"
    t.index ["job_geocoding_id"], :name => "index_customers_on_job_geocoding_id"
    t.index ["job_optimizer_id"], :name => "index_customers_on_job_optimizer_id"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.string   "progress",   default: "0", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], :name => "delayed_jobs_priority"
  end

  create_table "destinations", force: true do |t|
    t.string   "name"
    t.string   "street"
    t.string   "postalcode"
    t.string   "city"
    t.float    "lat"
    t.float    "lng"
    t.integer  "quantity"
    t.time     "open"
    t.time     "close"
    t.integer  "customer_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "detail"
    t.string   "comment"
    t.string   "ref"
    t.time     "take_over"
    t.float    "geocoding_accuracy"
    t.index ["customer_id"], :name => "index_destinations_on_customer_id"
    t.foreign_key ["customer_id"], "customers", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_destinations_customer_id"
  end

  create_table "tags", force: true do |t|
    t.string   "label"
    t.string   "color"
    t.string   "icon"
    t.integer  "customer_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["customer_id"], :name => "index_tags_on_customer_id"
    t.foreign_key ["customer_id"], "customers", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_tags_customer_id"
  end

  create_table "destinations_tags", id: false, force: true do |t|
    t.integer "destination_id", null: false
    t.integer "tag_id",         null: false
    t.index ["destination_id"], :name => "fk__destinations_tags_destination_id"
    t.index ["tag_id"], :name => "fk__destinations_tags_tag_id"
    t.foreign_key ["destination_id"], "destinations", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_destinations_tags_destination_id"
    t.foreign_key ["tag_id"], "tags", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_destinations_tags_tag_id"
  end

  create_table "layers", force: true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "attribution"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "urlssl"
  end

  create_table "zonings", force: true do |t|
    t.string   "name"
    t.integer  "customer_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["customer_id"], :name => "index_zonings_on_customer_id"
    t.foreign_key ["customer_id"], "customers", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_zonings_customer_id"
  end

  create_table "plannings", force: true do |t|
    t.string   "name"
    t.integer  "customer_id",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zoning_id"
    t.boolean  "zoning_out_of_date"
    t.index ["customer_id"], :name => "index_plannings_on_customer_id"
    t.index ["zoning_id"], :name => "fk__plannings_zoning_id"
    t.foreign_key ["customer_id"], "customers", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_plannings_customer_id"
    t.foreign_key ["zoning_id"], "zonings", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_plannings_zoning_id"
  end

  create_table "plannings_tags", id: false, force: true do |t|
    t.integer "planning_id", null: false
    t.integer "tag_id",      null: false
    t.index ["planning_id"], :name => "fk__plannings_tags_planning_id"
    t.index ["tag_id"], :name => "fk__plannings_tags_tag_id"
    t.foreign_key ["planning_id"], "plannings", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_plannings_tags_planning_id"
    t.foreign_key ["tag_id"], "tags", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_plannings_tags_tag_id"
  end

  create_table "routers", force: true do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stores", force: true do |t|
    t.string   "name"
    t.string   "street"
    t.string   "postalcode"
    t.string   "city"
    t.float    "lat", null: false
    t.float    "lng", null: false
    t.time     "open"
    t.time     "close"
    t.integer  "customer_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["customer_id"], :name => "fk__stores_customer_id"
    t.foreign_key ["customer_id"], "customers", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_stores_customer_id"
  end

  create_table "vehicles", force: true do |t|
    t.string   "name"
    t.float    "emission"
    t.float    "consumption"
    t.integer  "capacity"
    t.string   "color"
    t.time     "open"
    t.time     "close"
    t.integer  "customer_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tomtom_id"
    t.integer  "store_start_id", null: false
    t.integer  "store_stop_id",  null: false
    t.integer  "router_id"
    t.index ["customer_id"], :name => "index_vehicles_on_customer_id"
    t.index ["store_start_id"], :name => "fk__vehicles_store_start_id"
    t.index ["store_stop_id"], :name => "fk__vehicles_store_stop_id"
    t.foreign_key ["customer_id"], "customers", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_vehicles_customer_id"
    t.foreign_key ["router_id"], "routers", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_vehicles_router_id"
    t.foreign_key ["store_start_id"], "stores", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_vehicles_store_start_id"
    t.foreign_key ["store_stop_id"], "stores", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_vehicles_store_stop_id"
  end

  create_table "routes", force: true do |t|
    t.float    "distance"
    t.float    "emission"
    t.integer  "planning_id", null: false
    t.integer  "vehicle_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "start"
    t.datetime "end"
    t.boolean  "hidden"
    t.boolean  "locked"
    t.datetime "build_at"
    t.boolean  "out_of_date"
    t.text     "stop_trace"
    t.boolean  "stop_out_of_drive_time"
    t.float    "stop_distance"
    t.string   "ref"
    t.index ["planning_id"], :name => "index_routes_on_planning_id"
    t.index ["vehicle_id"], :name => "index_routes_on_vehicle_id"
    t.foreign_key ["planning_id"], "plannings", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_routes_planning_id"
    t.foreign_key ["vehicle_id"], "vehicles", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_routes_vehicle_id"
  end

  create_table "stops", force: true do |t|
    t.integer  "index"
    t.boolean  "active"
    t.float    "distance"
    t.text     "trace"
    t.integer  "route_id",          null: false
    t.integer  "destination_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "time"
    t.boolean  "out_of_window"
    t.boolean  "out_of_capacity"
    t.boolean  "out_of_drive_time"
    t.integer  "wait_time"
    t.index ["destination_id"], :name => "index_stops_on_destination_id"
    t.index ["route_id"], :name => "index_stops_on_route_id"
    t.foreign_key ["destination_id"], "destinations", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_stops_destination_id"
    t.foreign_key ["route_id"], "routes", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_stops_route_id"
  end

  create_table "stores_vehicules", id: false, force: true do |t|
    t.integer "store_id",   null: false
    t.integer "vehicle_id", null: false
    t.index ["store_id"], :name => "index_stores_vehicules_on_store_id"
    t.index ["vehicle_id"], :name => "index_stores_vehicules_on_vehicle_id"
    t.foreign_key ["store_id"], "stores", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_stores_vehicules_store_id"
    t.foreign_key ["vehicle_id"], "vehicles", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_stores_vehicules_vehicle_id"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.boolean  "admin"
    t.integer  "customer_id"
    t.integer  "layer_id",                            null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_key",                             null: false
    t.index ["customer_id"], :name => "fk__users_customer_id"
    t.index ["email"], :name => "index_users_on_email", :unique => true
    t.index ["layer_id"], :name => "fk__users_layer_id"
    t.index ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
    t.foreign_key ["customer_id"], "customers", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_users_customer_id"
    t.foreign_key ["layer_id"], "layers", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_users_layer_id"
  end

  create_table "zones", force: true do |t|
    t.text     "polygon"
    t.integer  "zoning_id",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vehicle_id"
    t.index ["vehicle_id"], :name => "fk__zones_vehicle_id"
    t.index ["zoning_id"], :name => "index_zones_on_zoning_id"
    t.foreign_key ["vehicle_id"], "vehicles", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_zones_vehicle_id"
    t.foreign_key ["zoning_id"], "zonings", ["id"], :on_update => :no_action, :on_delete => :no_action, :deferrable => true, :name => "fk_zones_zoning_id"
  end

end
