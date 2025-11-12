Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API v1 routes
  namespace :api do
    namespace :v1 do
      # POST /v1/entries - Create ledger transactions with idempotency
      resources :entries, only: [ :create ]

      # GET /v1/accounts/:account_id/balance - Get account balance
      get "accounts/:account_id/balance", to: "balances#show", as: :account_balance
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
