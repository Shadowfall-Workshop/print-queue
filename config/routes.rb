 Rails.application.routes.draw do
  devise_for :users
  
  resources :users, only: [] do
    collection do
      post :sync_etsy_orders
    end
  end

  # Root path
  root 'queue_items#index'

  # Redirect /queue_items to the root path
  #get '/queue_items', to: redirect('/')

  resources :queue_items, only: [:index, :new, :create, :edit, :update, :show, :destroy]
  resources :api_keys, only: [:new, :create, :destroy]

  namespace :api do
    namespace :v1 do
      resources :queue_items, only: [:create]
    end
  end

  # Integrations:
namespace :oauth do
  get "etsy/connect", to: "etsy#connect"
  get "etsy/callback", to: "etsy#callback"
  delete "etsy/disconnect", to: "etsy#disconnect"
end


  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

end