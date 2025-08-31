class Bank < ApplicationRecord
  validates :currency, inclusion: { in: Rails.application.config.available_currencies }

  def display_name
    "#{name} (#{currency})"
  end
end
