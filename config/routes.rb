Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :jobs, only: [:index, :show, :new, :create]
  resource :question, only: [:new, :create]

  root "jobs#index"
end
