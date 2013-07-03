require 'sidekiq/web'

RorWebsite::Application.routes.draw do
  # Route to the sidekiq manager
  mount Sidekiq::Web => '/sidekiq'
  
  # Redirect the root url to the uwf page (www.berndtlab.pitt.edu)
  root :to => 'static_pages#home'
  
  # Aliases to specific actions.
  match '/signup',  :to => 'users#new'
  match '/signin',  :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy', :via => :delete
  match '/phenotypes', :to => 'phenotypes#index'
  
  # Most reload ajax calls below follow this template
  #post '/:type/:id/:controller/:action
  
  # User routes
  resources :users
  # User AJAX calls
  post '/users/accept_group'
  post '/users/decline_group'
  post '/users/leave_group'
  post '/users/delete_group'
  post '/:type/:id/members/reload' => 'users#reload'
  
  # Group routes
  resources :groups, :only => [:new, :create, :show, :destroy, :modify_members]
  # To reload the group_panel div via AJAX
  post '/:type/:id/groups/reload' => 'groups#reload'
  
  # Micropost routes, using nested resources
  resources :users do
    resources :microposts, :only => [:create, :destroy,]
  end
  # To reload the micropost_panel div via AJAX
  post '/:type/:id/microposts/reload' => 'microposts#reload'
  
  # Job routes, using nested resources
  resources :users do
    resources :jobs
  end
  # To report back all job percentages for the group or user
  post '/jobs/percentages'
  # To reload the job_panel div via AJAX
  post '/:type/:id/jobs/reload' => 'jobs#reload'
  
  # Datafile routes
  resources :users do
    resources :datafiles
  end
  # To reload the datafile_panel div via AJAX
  post '/:type/:id/datafiles/reload' => 'datafiles#reload'
  

  # Task routes, using nested resources
  resources :groups do
    resources :tasks, :only => [:create, :destroy,]
  end
  # To report back the status of all tasks for the group
  post '/tasks/check'
  # To reload the task_panel div via AJAX
  post '/:type/:id/tasks/reload' => 'tasks#reload'


  # Other app routes
  resources :sessions, :only => [:new, :create, :destroy]

  # Bulk routes
  resources :bulk
  get '/bulk/progress/:id' => 'bulk#progress' 

  # Reports routes
  resources :reports
  get '/reports/progress/:id' => 'reports#progress'  

  # UWF routes
  resources :uwf, :only => [:index, :new, :create]
  # UWF AJAX calls
  get '/uwf/progress/:id' => 'uwf#progress'
  get '/uwf/generate/:id' => 'uwf#generate'
  post '/uwf/get_circos_panel' => 'uwf#get_circos_panel'
  
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
  match 'data/*path' => 'static#show', :defaults => { :format => 'txt' }
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
