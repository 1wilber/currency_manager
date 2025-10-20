class Bank < ApplicationRecord
  validates :currency, inclusion: { in: Rails.application.config.available_currencies }, presence: true
  validates :name, presence: true

  has_many :outgoings, as: :sender, class_name: "Transaction"
  has_many :incomings, as: :receiver, class_name: "Transaction"
  has_many :bank_balances, dependent: :destroy

  scope :default, -> { where(name: "default").first  }

  def self.ves_default
    Bank.find_or_create_by(name: "VES", currency: "VES")
  end


  def balance
    incomings.sum(:total) - outgoings.sum(:total)
  end

  def display_name
    "#{name} (#{currency})"
  end
end
