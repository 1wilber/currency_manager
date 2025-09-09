class Bank < ApplicationRecord
  validates :currency, inclusion: { in: Rails.application.config.available_currencies }, presence: true
  validates :name, presence: true
  has_many :balances, class_name: "BankBalance", dependent: :destroy

  def display_name
    "#{name} (#{currency})"
  end
end
