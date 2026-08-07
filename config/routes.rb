Rails.application.routes.draw do
  resources :loyalty_cards, only: [ :index, :create, :show ] do
    member do
      get :wallet
      get :offline
    end
  end
  resources :newsletters do
    collection do
      get :report
    end
    member do
      post :deliver
    end
  end
  namespace :customer do
    resource :gocardless_setup, only: [ :create ]
    resources :newsletters, only: [ :index, :show ] do
      collection do
        post :subscribe
      end
      member do
        post :unsubscribe
      end
    end
    resources :loyalty_programs, only: [ :index, :show, :create ]
  end
  resources :suppliers do
    member do
      get :inventory
    end
  end
  resources :reports, only: [ :index ]
  resources :supplier_requests, only: [ :index, :new, :create, :update, :destroy ]
  resources :order_items
  resources :orders do
    member do
      patch :awaiting_collection
      patch :complete
    end
    resources :notes, only: [ :create ]
  end
  resources :tasks do
    member do
      patch :complete
      patch :incomplete
    end
  end
  resource :shop, only: [ :show ] do
    resources :categories, only: [ :show ], controller: "shop/categories"
    resources :products, only: [ :show ], controller: "shop/products"
  end
  resource :cart, only: [ :show, :update, :destroy ] do
    post :add_item
    post :remove_item
  end
  resource :checkout, only: [ :show, :create ]

  resources :inventory_items do
    resources :supplier_prices, only: [ :create, :destroy ]
    member do
      delete :really_destroy
    end
    resources :inventory_levels, only: [ :create, :update, :destroy ] do
      collection do
        post :transfer
      end
    end
  end
  resources :inventory_levels, only: [ :index, :show, :edit, :update, :destroy ]
  resources :locations
  resources :inventory_groups
  resources :customers do
    member do
      delete :really_destroy
    end
  end
  resources :accounts do
    member do
      post :join
      post :leave
      get :audits
    end
    resources :account_users, shallow: true
  end
  resources :support_requests do
    member do
      post :extend
    end
    resources :comments, controller: "support_request_comments", only: %i[ create update ]
  end
  # Auditing
  mount Audits1984::Engine => "/console"

  # Authentication
  resources :users do
    member do
      delete :really_destroy
    end
  end
  resource :session
  resources :store_memberships, only: [ :create ]
  resource :managed_account, only: [ :update, :destroy ]
  resources :passwords, param: :token

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource :settings, only: [ :show, :update, :destroy ] do
    member do
      patch :update_password
      post :logout_sessions
    end
  end
  resource :two_factor_auth, only: [ :show, :create, :destroy ]
  resource :two_factor_verification, only: [ :new, :create ]
  resource :onboarding, only: [ :show, :update ]
  resource :security_setup, only: [ :show, :create ] do
    member do
      get :password
      patch :update_password
      get :two_factor
    end
  end

  get "dashboard" => "pages#dashboard"
  root "pages#home"

  if Rails.env.test?
    get "test/login/:user_id" => "sessions#test_login", as: :test_login
  end
end
