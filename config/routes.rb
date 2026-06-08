Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  # ---- storefront ----
  get "shop/:slug", to: "shop#show", as: :shop_category
  get "sets", to: "sets#index", as: :sets
  get "set/:id", to: "sets#show", as: :product_set
  get "collections", to: "collections#index", as: :collections
  get "collection/:slug", to: "collections#show", as: :collection
  get "campaign/:slug", to: "campaigns#show", as: :campaign
  get "product/:id", to: "products#show", as: :product
  get "about", to: "pages#about", as: :about

  # ---- cart ----
  post   "cart/items",   to: "cart#add",    as: :cart_add
  patch  "cart/items",   to: "cart#update", as: :cart_update
  delete "cart/items",   to: "cart#remove", as: :cart_remove

  # ---- checkout ----
  get  "checkout", to: "checkout#new",    as: :checkout
  post "checkout", to: "checkout#create"
  get  "checkout/confirmation/:number", to: "checkout#confirmation", as: :checkout_confirmation

  # ---- admin ----
  namespace :admin do
    get  "login",  to: "sessions#new"
    post "login",  to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"

    get  "analytics", to: "analytics#index"
    delete "analytics", to: "analytics#reset", as: :reset_analytics

    resources :orders, only: [:index, :show, :update, :destroy], param: :number
    resources :categories
    resources :products
    resources :sets, controller: "product_sets"
    resources :collections
    resources :campaigns
    resource :about, only: [:edit, :update], controller: "about"
  end
end
