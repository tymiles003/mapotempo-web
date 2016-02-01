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

ActiveRecord::Schema.define(version: 20160201165009) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customers", force: :cascade do |t|
    t.date     "end_subscription"
    t.time     "take_over"
    t.integer  "job_destination_geocoding_id"
    t.integer  "job_optimizer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                            limit: 255
    t.string   "tomtom_account",                  limit: 255
    t.string   "tomtom_user",                     limit: 255
    t.string   "tomtom_password",                 limit: 255
    t.integer  "router_id",                                                   null: false
    t.boolean  "print_planning_annotating"
    t.text     "print_header"
    t.string   "masternaut_user",                 limit: 255
    t.string   "masternaut_password",             limit: 255
    t.boolean  "enable_orders",                               default: false, null: false
    t.boolean  "test",                                        default: false, null: false
    t.string   "alyacom_association",             limit: 255
    t.integer  "optimization_cluster_size"
    t.integer  "optimization_time"
    t.integer  "optimization_soft_upper_bound"
    t.integer  "profile_id",                                                  null: false
    t.float    "speed_multiplicator"
    t.string   "default_country",                                             null: false
    t.boolean  "enable_tomtom",                               default: false, null: false
    t.boolean  "enable_masternaut",                           default: false, null: false
    t.boolean  "enable_alyacom",                              default: false, null: false
    t.integer  "job_store_geocoding_id"
    t.integer  "reseller_id",                                                 null: false
    t.boolean  "enable_multi_vehicle_usage_sets",             default: false, null: false
    t.boolean  "print_stop_time",                             default: true,  null: false
    t.string   "ref"
    t.boolean  "enable_references",                           default: true
    t.boolean  "enable_multi_visits",                         default: true,  null: false
  end

  add_index "customers", ["job_destination_geocoding_id"], name: "index_customers_on_job_destination_geocoding_id", using: :btree
  add_index "customers", ["job_optimizer_id"], name: "index_customers_on_job_optimizer_id", using: :btree
  add_index "customers", ["job_store_geocoding_id"], name: "index_customers_on_job_store_geocoding_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",               default: 0,   null: false
    t.integer  "attempts",               default: 0,   null: false
    t.text     "handler",                              null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "progress",   limit: 255, default: "0", null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "destinations", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "street",             limit: 255
    t.string   "postalcode",         limit: 255
    t.string   "city",               limit: 255
    t.float    "lat"
    t.float    "lng"
    t.integer  "customer_id",                    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "detail",             limit: 255
    t.text     "comment"
    t.float    "geocoding_accuracy"
    t.string   "country"
    t.integer  "geocoding_level"
    t.string   "phone_number"
    t.string   "ref"
  end

  add_index "destinations", ["customer_id"], name: "fk__destinations_customer_id", using: :btree

  create_table "destinations_tags", id: false, force: :cascade do |t|
    t.integer "destination_id", null: false
    t.integer "tag_id",         null: false
  end

  add_index "destinations_tags", ["destination_id"], name: "index_destinations_tags_on_destination_id", using: :btree
  add_index "destinations_tags", ["tag_id"], name: "index_destinations_tags_on_tag_id", using: :btree

  create_table "layers", force: :cascade do |t|
    t.string   "name",                        null: false
    t.string   "url",                         null: false
    t.string   "attribution",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "urlssl",                      null: false
    t.string   "source",                      null: false
    t.boolean  "overlay",     default: false
  end

  create_table "layers_profiles", id: false, force: :cascade do |t|
    t.integer "profile_id"
    t.integer "layer_id"
  end

  create_table "order_arrays", force: :cascade do |t|
    t.string   "name",        limit: 255, null: false
    t.date     "base_date",               null: false
    t.integer  "length",                  null: false
    t.integer  "customer_id",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "order_arrays", ["customer_id"], name: "fk__order_arrays_customer_id", using: :btree

  create_table "orders", force: :cascade do |t|
    t.integer  "shift",          null: false
    t.integer  "order_array_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "visit_id",       null: false
  end

  add_index "orders", ["order_array_id"], name: "fk__orders_order_array_id", using: :btree
  add_index "orders", ["visit_id"], name: "index_orders_on_visit_id", using: :btree

  create_table "orders_products", id: false, force: :cascade do |t|
    t.integer "order_id",   null: false
    t.integer "product_id", null: false
  end

  add_index "orders_products", ["order_id"], name: "fk__orders_products_order_id", using: :btree
  add_index "orders_products", ["product_id"], name: "fk__orders_products_product_id", using: :btree

  create_table "plannings", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.integer  "customer_id",                      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "zoning_id"
    t.boolean  "zoning_out_of_date"
    t.integer  "order_array_id"
    t.string   "ref"
    t.date     "date"
    t.integer  "vehicle_usage_set_id",             null: false
  end

  add_index "plannings", ["customer_id"], name: "fk__plannings_customer_id", using: :btree
  add_index "plannings", ["order_array_id"], name: "fk__plannings_order_array_id", using: :btree
  add_index "plannings", ["vehicle_usage_set_id"], name: "index_plannings_on_vehicle_usage_set_id", using: :btree
  add_index "plannings", ["zoning_id"], name: "fk__plannings_zoning_id", using: :btree

  create_table "plannings_tags", id: false, force: :cascade do |t|
    t.integer "planning_id", null: false
    t.integer "tag_id",      null: false
  end

  add_index "plannings_tags", ["planning_id"], name: "fk__plannings_tags_planning_id", using: :btree
  add_index "plannings_tags", ["tag_id"], name: "fk__plannings_tags_tag_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.string   "name",        limit: 255, null: false
    t.string   "code",        limit: 255, null: false
    t.integer  "customer_id",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "products", ["customer_id"], name: "fk__products_customer_id", using: :btree

  create_table "profiles", force: :cascade do |t|
    t.string "name"
  end

  create_table "profiles_routers", id: false, force: :cascade do |t|
    t.integer "profile_id"
    t.integer "router_id"
  end

  create_table "resellers", force: :cascade do |t|
    t.string   "host",        null: false
    t.string   "name",        null: false
    t.string   "welcome_url"
    t.string   "help_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "logo_large"
    t.string   "logo_small"
    t.string   "favicon"
  end

  create_table "routers", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "url_time",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",            limit: 255, default: "RouterOsrm", null: false
    t.string   "ref"
    t.string   "url_isochrone"
    t.string   "url_isodistance"
    t.string   "url_distance"
    t.string   "mode",                                               null: false
  end

  create_table "routes", force: :cascade do |t|
    t.float    "distance"
    t.float    "emission"
    t.integer  "planning_id",                        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "start"
    t.datetime "end"
    t.boolean  "hidden"
    t.boolean  "locked"
    t.boolean  "out_of_date"
    t.text     "stop_trace"
    t.boolean  "stop_out_of_drive_time"
    t.float    "stop_distance"
    t.string   "ref",                    limit: 255
    t.string   "color"
    t.integer  "vehicle_usage_id"
    t.integer  "stop_drive_time"
  end

  add_index "routes", ["planning_id"], name: "fk__routes_planning_id", using: :btree
  add_index "routes", ["vehicle_usage_id"], name: "index_routes_on_vehicle_usage_id", using: :btree

  create_table "stops", force: :cascade do |t|
    t.integer  "index"
    t.boolean  "active"
    t.float    "distance"
    t.text     "trace"
    t.integer  "route_id",                                      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "time"
    t.boolean  "out_of_window"
    t.boolean  "out_of_capacity"
    t.boolean  "out_of_drive_time"
    t.integer  "wait_time"
    t.integer  "lock_version",      default: 0,                 null: false
    t.string   "type",              default: "StopDestination", null: false
    t.integer  "drive_time"
    t.integer  "visit_id"
  end

  add_index "stops", ["route_id"], name: "fk__stops_route_id", using: :btree
  add_index "stops", ["visit_id"], name: "index_stops_on_visit_id", using: :btree

  create_table "stores", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "street",             limit: 255
    t.string   "postalcode",         limit: 255
    t.string   "city",               limit: 255
    t.float    "lat"
    t.float    "lng"
    t.integer  "customer_id",                    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "country"
    t.string   "ref"
    t.float    "geocoding_accuracy"
    t.integer  "geocoding_level"
    t.string   "color"
    t.string   "icon"
    t.string   "icon_size"
  end

  add_index "stores", ["customer_id"], name: "fk__stores_customer_id", using: :btree

  create_table "stores_vehicules", id: false, force: :cascade do |t|
    t.integer "store_id",   null: false
    t.integer "vehicle_id", null: false
  end

  add_index "stores_vehicules", ["store_id"], name: "fk__stores_vehicules_store_id", using: :btree
  add_index "stores_vehicules", ["vehicle_id"], name: "fk__stores_vehicules_vehicle_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "label",       limit: 255
    t.integer  "customer_id",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "color",       limit: 255
    t.string   "icon",        limit: 255
  end

  add_index "tags", ["customer_id"], name: "fk__tags_customer_id", using: :btree

  create_table "tags_visits", id: false, force: :cascade do |t|
    t.integer "visit_id", null: false
    t.integer "tag_id",   null: false
  end

  add_index "tags_visits", ["tag_id"], name: "index_tags_visits_on_tag_id", using: :btree
  add_index "tags_visits", ["visit_id"], name: "index_tags_visits_on_visit_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.integer  "customer_id"
    t.integer  "layer_id",                                        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "api_key",                limit: 255,              null: false
    t.integer  "reseller_id"
    t.string   "url_click2call"
    t.string   "ref"
  end

  add_index "users", ["api_key"], name: "index_users_on_api_key", using: :btree
  add_index "users", ["customer_id"], name: "fk__users_customer_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["layer_id"], name: "fk__users_layer_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "vehicle_usage_sets", force: :cascade do |t|
    t.integer  "customer_id",        null: false
    t.string   "name",               null: false
    t.time     "open",               null: false
    t.time     "close",              null: false
    t.integer  "store_start_id"
    t.integer  "store_stop_id"
    t.integer  "store_rest_id"
    t.time     "rest_start"
    t.time     "rest_stop"
    t.time     "rest_duration"
    t.time     "service_time_start"
    t.time     "service_time_end"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_usage_sets", ["customer_id"], name: "index_vehicle_usage_sets_on_customer_id", using: :btree
  add_index "vehicle_usage_sets", ["store_rest_id"], name: "index_vehicle_usage_sets_on_store_rest_id", using: :btree
  add_index "vehicle_usage_sets", ["store_start_id"], name: "index_vehicle_usage_sets_on_store_start_id", using: :btree
  add_index "vehicle_usage_sets", ["store_stop_id"], name: "index_vehicle_usage_sets_on_store_stop_id", using: :btree

  create_table "vehicle_usages", force: :cascade do |t|
    t.integer  "vehicle_usage_set_id", null: false
    t.integer  "vehicle_id",           null: false
    t.time     "open"
    t.time     "close"
    t.integer  "store_start_id"
    t.integer  "store_stop_id"
    t.integer  "store_rest_id"
    t.time     "rest_start"
    t.time     "rest_stop"
    t.time     "rest_duration"
    t.time     "service_time_start"
    t.time     "service_time_end"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vehicle_usages", ["store_rest_id"], name: "index_vehicle_usages_on_store_rest_id", using: :btree
  add_index "vehicle_usages", ["store_start_id"], name: "index_vehicle_usages_on_store_start_id", using: :btree
  add_index "vehicle_usages", ["store_stop_id"], name: "index_vehicle_usages_on_store_stop_id", using: :btree
  add_index "vehicle_usages", ["vehicle_id"], name: "index_vehicle_usages_on_vehicle_id", using: :btree
  add_index "vehicle_usages", ["vehicle_usage_set_id"], name: "index_vehicle_usages_on_vehicle_usage_set_id", using: :btree

  create_table "vehicles", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.float    "emission"
    t.float    "consumption"
    t.integer  "capacity"
    t.string   "color",                           null: false
    t.integer  "customer_id",                     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tomtom_id",           limit: 255
    t.integer  "router_id"
    t.string   "masternaut_ref",      limit: 255
    t.float    "speed_multiplicator"
    t.string   "ref"
    t.string   "capacity_unit"
    t.string   "contact_email"
  end

  add_index "vehicles", ["customer_id"], name: "fk__vehicles_customer_id", using: :btree
  add_index "vehicles", ["router_id"], name: "fk__vehicles_router_id", using: :btree

  create_table "visits", force: :cascade do |t|
    t.float    "quantity"
    t.time     "open"
    t.time     "close"
    t.string   "ref"
    t.time     "take_over"
    t.integer  "destination_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "visits", ["destination_id"], name: "index_visits_on_destination_id", using: :btree

  create_table "zones", force: :cascade do |t|
    t.text     "polygon"
    t.integer  "zoning_id",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "vehicle_id"
  end

  add_index "zones", ["vehicle_id"], name: "fk__zones_vehicle_id", using: :btree
  add_index "zones", ["zoning_id"], name: "fk__zones_zoning_id", using: :btree

  create_table "zonings", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.integer  "customer_id",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "zonings", ["customer_id"], name: "fk__zonings_customer_id", using: :btree

  add_foreign_key "customers", "profiles"
  add_foreign_key "destinations", "customers", name: "fk_destinations_customer_id", on_delete: :cascade
  add_foreign_key "destinations_tags", "destinations", on_delete: :cascade
  add_foreign_key "destinations_tags", "tags", on_delete: :cascade
  add_foreign_key "order_arrays", "customers", name: "fk_order_arrays_customer_id", on_delete: :cascade
  add_foreign_key "orders", "order_arrays", name: "fk_orders_order_array_id", on_delete: :cascade
  add_foreign_key "orders", "visits", on_delete: :cascade
  add_foreign_key "orders_products", "orders", name: "fk_orders_products_order_id", on_delete: :cascade
  add_foreign_key "orders_products", "products", name: "fk_orders_products_product_id", on_delete: :cascade
  add_foreign_key "plannings", "customers", name: "fk_plannings_customer_id", on_delete: :cascade
  add_foreign_key "plannings", "order_arrays", name: "fk_plannings_order_array_id"
  add_foreign_key "plannings", "vehicle_usage_sets"
  add_foreign_key "plannings", "zonings", name: "fk_plannings_zoning_id"
  add_foreign_key "plannings_tags", "plannings", name: "fk_plannings_tags_planning_id", on_delete: :cascade
  add_foreign_key "plannings_tags", "tags", name: "fk_plannings_tags_tag_id", on_delete: :cascade
  add_foreign_key "products", "customers", name: "fk_products_customer_id", on_delete: :cascade
  add_foreign_key "routes", "plannings", name: "fk_routes_planning_id", on_delete: :cascade
  add_foreign_key "routes", "vehicle_usages"
  add_foreign_key "stops", "routes", name: "fk_stops_route_id", on_delete: :cascade
  add_foreign_key "stops", "visits", on_delete: :cascade
  add_foreign_key "stores", "customers", name: "fk_stores_customer_id", on_delete: :cascade
  add_foreign_key "stores_vehicules", "stores", name: "fk_stores_vehicules_store_id", on_delete: :cascade
  add_foreign_key "stores_vehicules", "vehicles", name: "fk_stores_vehicules_vehicle_id", on_delete: :cascade
  add_foreign_key "tags", "customers", name: "fk_tags_customer_id", on_delete: :cascade
  add_foreign_key "tags_visits", "tags", on_delete: :cascade
  add_foreign_key "tags_visits", "visits", on_delete: :cascade
  add_foreign_key "users", "customers", name: "fk_users_customer_id"
  add_foreign_key "users", "layers", name: "fk_users_layer_id"
  add_foreign_key "vehicle_usage_sets", "customers"
  add_foreign_key "vehicle_usage_sets", "stores", column: "store_rest_id"
  add_foreign_key "vehicle_usage_sets", "stores", column: "store_start_id"
  add_foreign_key "vehicle_usage_sets", "stores", column: "store_stop_id"
  add_foreign_key "vehicle_usages", "stores", column: "store_rest_id"
  add_foreign_key "vehicle_usages", "stores", column: "store_start_id"
  add_foreign_key "vehicle_usages", "stores", column: "store_stop_id"
  add_foreign_key "vehicle_usages", "vehicle_usage_sets"
  add_foreign_key "vehicle_usages", "vehicles"
  add_foreign_key "vehicles", "customers", name: "fk_vehicles_customer_id", on_delete: :cascade
  add_foreign_key "vehicles", "routers", name: "fk_vehicles_router_id"
  add_foreign_key "visits", "destinations", on_delete: :cascade
  add_foreign_key "zones", "vehicles", name: "fk_zones_vehicle_id"
  add_foreign_key "zones", "zonings", name: "fk_zones_zoning_id", on_delete: :cascade
  add_foreign_key "zonings", "customers", name: "fk_zonings_customer_id", on_delete: :cascade
end
