class Bank < ApplicationRecord
  validates :currency, inclusion: { in: Rails.application.config.available_currencies }
end
