class Bank < ApplicationRecord
  validates :currency, inclusion: { in: Rails.application.config.available_currencies }, presence: true
  validates :name, presence: true

  has_many :outgoings, as: :sender, class_name: "Transaction"
  has_many :incomings, as: :receiver, class_name: "Transaction"


  def balance
    incomings.sum(:total) - outgoings.sum(:total)
  end

  def display_name
    "#{name} (#{currency})"
  end
end
