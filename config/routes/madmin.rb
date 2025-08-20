# Below are the routes for madmin
namespace :madmin do
  resources :transactions
  resources :customers
  root to: "dashboard#show"
end
