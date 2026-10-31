Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "sitemap.xml", to: "sitemaps#show", defaults: { format: "xml" }, as: :sitemap

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

  # ---- online payment (myPOS Checkout) ----
  get   "checkout/pay/:number",          to: "payments#pay",    as: :checkout_pay
  post  "payments/mypos/notify",         to: "payments#notify", as: :mypos_notify
  match "payments/mypos/ok/:number",     to: "payments#ok",     as: :mypos_ok,     via: [ :get, :post ]
  match "payments/mypos/cancel/:number", to: "payments#cancel", as: :mypos_cancel, via: [ :get, :post ]

  # ---- admin ----
  # Studio login lives at an unguessable top-level path. Kept named admin_login
  # so existing redirects (require_admin) and the form resolve to it.
  get  "samobibipipatuk", to: "admin/sessions#new", as: :admin_login
  post "samobibipipatuk", to: "admin/sessions#create"

  namespace :admin do
    delete "logout", to: "sessions#destroy"

    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"

    get "analytics", to: "analytics#index"
    delete "analytics", to: "analytics#reset", as: :reset_analytics

    resources :orders, only: [ :index, :show, :update, :destroy ], param: :number
    resources :categories
    resources :products do
      resources :variants, only: [ :new, :create, :edit, :update, :destroy ]
    end
    resources :sets, controller: "product_sets"
    resources :collections
    resources :campaigns
    resources :variant_attributes, path: "attributes"
    resource :about, only: [ :edit, :update ], controller: "about"
    resource :home_page, only: [ :edit, :update ], controller: "home_page"
    resource :vacation, only: [ :edit, :update ], controller: "vacation"
    resource :payments, only: [ :edit, :update ], controller: "payment_settings"
    resources :delivery_rates, path: "delivery", only: [ :index, :create, :update, :destroy ]
  end
end
