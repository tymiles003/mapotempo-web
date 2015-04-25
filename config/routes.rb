Rails.application.routes.draw do
  get '/api/swagger_doc.json/:all(*format)' => redirect('/api/swagger_doc/%{all}%{format}') # Workaround for silly swagger-codegen
  mount ApiRoot => '/api'

  devise_for :users, :controllers => {:registrations => "registrations"}
  get 'user_settings/:id' => 'users#show', :as => 'show_user'
  get 'edit_user_settings/:id' => 'users#edit_settings', :as => 'edit_user_settings'
  patch 'user_settings/:id' => 'users#update_settings', :as => 'update_user_settings'

  namespace :admin do
    resources :users
    delete 'users' => 'users#destroy_multiple'
    resources :profiles
  end

  resources :tags
  delete 'tags' => 'tags#destroy_multiple'

  resources :customers
  delete 'customers' => 'customers#destroy_multiple'

  resources :vehicles

  resources :destinations
  get 'destination/import_template' => 'destinations#import_template'
  get 'destination/import' => 'destinations#import'
  post 'destinations/upload' => 'destinations#upload', :as => 'destinations_imports'
  delete 'destinations' => 'destinations#clear'

  resources :stores
  delete 'stores' => 'stores#destroy_multiple'

  resources :plannings do
    patch ':route_id/:destination_id/move/:index' => 'plannings#move'
    get 'refresh'
    patch 'switch'
    patch 'duplicate'
    patch 'automatic_insert/:destination_id' => 'plannings#automatic_insert'
    patch ':route_id/active/:active' => 'plannings#active'
    patch ':route_id/:destination_id' => 'plannings#update_stop'
    get 'optimize_each' => 'plannings#optimize_each_routes'
    get ':route_id/optimize' => 'plannings#optimize_route'
  end
  delete 'plannings' => 'plannings#destroy_multiple'

  resources :products
  delete 'products' => 'products#destroy_multiple'

  resources :routes

  get '/zonings/new/planning/:planning_id' => 'zonings#new'
  resources :zonings do
    get 'edit/planning/:planning_id' => 'zonings#edit'
    get 'planning/:planning_id' => 'zonings#show'
    patch 'duplicate'
  end
  delete 'zonings' => 'zonings#destroy_multiple'

  resources :order_arrays do
    patch 'duplicate'
  end
  delete 'order_arrays' => 'order_arrays#destroy_multiple'

  get '/unsupported_browser' => 'index#unsupported_browser'

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
