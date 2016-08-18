Rails.application.routes.draw do
  get '/api/0.1/swagger_doc.json/:all(*format)' => redirect('/api/0.1/swagger_doc/%{all}%{format}') # Workaround for silly swagger-codegen
  mount ApiRoot => '/api'

  devise_for :users, :controllers => {:registrations => "registrations"}
  devise_scope :user do
    unauthenticated do
      root 'index#index', as: :apikey_root, constraints: {url: /\?api_key=/}
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end

  get 'user_settings/:id' => 'users#show', :as => 'show_user'
  get 'edit_user_settings/:id' => 'users#edit_settings', :as => 'edit_user_settings'
  patch 'user_settings/:id' => 'users#update_settings', :as => 'update_user_settings'

  namespace :admin do
    resources :users do
      member do
        get :send_email
      end
    end
    delete 'users' => 'users#destroy_multiple'
    resources :profiles
    resources :resellers
  end

  namespace :api_web, path: 'api-web' do
    namespace :v01, path: '0.1' do
      match 'destinations' => 'destinations#index', :as => 'destinations', via: [:get, :post]
      get 'destinations/:id/edit_position' => 'destinations#edit_position', :as => 'edit_position_destination'
      patch 'destinations/:id/update_position' => 'destinations#update_position', :as => 'update_position_destination'

      match 'stores' => 'stores#index', :as => 'stores', via: [:get, :post]
      get 'stores/:id/edit_position' => 'stores#edit_position', :as => 'edit_position_store'
      patch 'stores/:id/update_position' => 'stores#update_position', :as => 'update_position_store'

      match 'zonings/:zoning_id/zones' => 'zones#index', :as => 'zones', via: [:get, :post]

      get 'plannings/:planning_id/routes' => 'routes#index', :as => 'routes'
    end
  end

  resources :tags
  delete 'tags' => 'tags#destroy_multiple'

  resources :customers do
    collection do
      delete :destroy_multiple
    end
    member do
      delete :delete_vehicle
      patch :duplicate
    end
    resources :users, only: [:edit, :update] do
      member do
        get :password
        patch :set_password
      end
    end
  end

  resources :vehicle_usage_sets do
    patch 'duplicate'
  end

  delete 'vehicle_usage_sets' => 'vehicle_usage_sets#destroy_multiple'

  resources :vehicle_usages do
    member do
      patch :toggle
    end
  end

  resources :destinations
  get 'destination/import_template' => 'destinations#import_template'
  get 'destination/import' => 'destinations#import'
  post 'destinations/upload_csv' => 'destinations#upload_csv', :as => 'destinations_import_csv'
  post 'destinations/upload_tomtom' => 'destinations#upload_tomtom', :as => 'destinations_import_tomtom'
  delete 'destinations' => 'destinations#clear'

  resources :stores
  get 'store/import_template' => 'stores#import_template'
  get 'store/import' => 'stores#import'
  post 'stores/upload_csv' => 'stores#upload_csv', :as => 'stores_import_csv'
  delete 'stores' => 'stores#destroy_multiple'

  resources :plannings do
    patch ':route_id/:stop_id/move' => 'plannings#move'
    patch ':route_id/:stop_id/move/:index' => 'plannings#move'
    get 'refresh'
    patch 'switch'
    patch 'duplicate'
    patch ':route_id/active/:active' => 'plannings#active'
    patch ':route_id/reverse_order' => 'plannings#reverse_order'
    patch ':route_id/:stop_id' => 'plannings#update_stop'
    get 'optimize' => 'plannings#optimize'
    get ':route_id/optimize' => 'plannings#optimize_route'
    member do
      patch :apply_zonings
      patch :automatic_insert
    end
  end
  delete 'plannings' => 'plannings#destroy_multiple'

  resources :products
  delete 'products' => 'products#destroy_multiple'

  resources :routes

  get '/zonings/new/planning/:planning_id' => 'zonings#new', as: :new_zonings_planning
  resources :zonings do
    get 'edit/planning/:planning_id' => 'zonings#edit'
    get 'planning/:planning_id' => 'zonings#show'
    patch 'duplicate'
    patch 'automatic' => 'zonings#automatic'
    patch 'automatic/planning/:planning_id' => 'zonings#automatic'
    patch 'from_planning/planning/:planning_id' => 'zonings#from_planning'
    patch 'isochrone' => 'zonings#isochrone'
    patch 'isodistance' => 'zonings#isodistance'
  end
  delete 'zonings' => 'zonings#destroy_multiple'

  resources :order_arrays do
    patch 'duplicate'
  end
  delete 'order_arrays' => 'order_arrays#destroy_multiple'

  get '/unsupported_browser' => 'index#unsupported_browser'

  get '/images/marker-home' => 'images#marker_home'
  get '/images/marker-home-:color' => 'images#marker_home'
  get '/images/marker' => 'images#marker'
  get '/images/marker-:color' => 'images#marker'
  get '/images/point' => 'images#point'
  get '/images/point-:color' => 'images#point'
  get '/images/square' => 'images#square'
  get '/images/square-:color' => 'images#square'
  get '/images/diamon' => 'images#diamon'
  get '/images/diamon-:color' => 'images#diamon'
  get '/images/star' => 'images#star'
  get '/images/star-:color' => 'images#star'
  get '/images/user' => 'images#user'
  get '/images/user-:color' => 'images#user'
  get '/images/point_large' => 'images#point_large'
  get '/images/point_large-:color' => 'images#point_large'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'index#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
