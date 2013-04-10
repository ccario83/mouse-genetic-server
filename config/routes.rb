require 'sidekiq/web'

RorWebsite::Application.routes.draw do
  # Route to the sidekiq manager
  mount Sidekiq::Web => '/sidekiq'
  
  # Redirect the root url to the uwf page
  root :to => 'static_pages#home'
  
  # Aliases 
  match '/signup',  :to => 'users#new'
  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy', :via => :delete
  match '/phenotypes', :to => 'phenotypes#index'
  
  # General routes
  #post '/users/job' => 'users#job'
  resources :users
  resources :groups, :only => [:new, :create, :show, :destroy, :modify_members]
  resources :sessions, :only => [:new, :create, :destroy]
  resources :microposts, :only => [:create, :destroy]
  resources :tasks, :only => [:create, :destroy, :check]
  resources :users do
    resources :jobs
  end
  
  # UWF routes
  resources :uwf, :only => [:index, :new, :create]
  get '/uwf/progress/:id' => 'uwf#progress'
  get '/uwf/generate/:id' => 'uwf#generate'
  
  # Phenotype routes
  get '/phenotypes/index'
  post '/phenotypes/show'
  post '/phenotypes/query'
  post '/phenotypes/check_stats'
  post '/phenotypes/submit'
  post '/phenotypes/analyze'
  get '/phenotypes/get_mpath_tree'
  get '/phenotypes/get_anat_tree'
  
  # Static Pages
  match '/home' => 'static_pages#home'
  match '/about' => 'static_pages#about'
  match '/contact' => 'static_pages#contact'
  match '/publications' => 'static_pages#publications'
  match '/screencasts' => 'static_pages#screencasts'
  match '/tool_descriptions' => 'static_pages#tool_descriptions'
  
  # Static handlers for development mode
  match 'data/*path' => 'static#show'
  match 'exists/data/*path' => 'static#exists'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with 'root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
