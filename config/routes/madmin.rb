# Below are the routes for madmin
namespace :madmin do
  resources :banks
  resources :transactions
  resources :customers
  root to: "dashboard#show"
end
