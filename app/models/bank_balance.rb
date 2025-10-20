class BankBalance < ApplicationRecord
  belongs_to :bank
  has_many :bank_balance_transactions, dependent: :destroy
  has_many :transactions, through: :bank_balance_transactions, source: :order

  def display_name
    "Saldo: #{balance} #{bank.currency} - 1 CLP = #{rate} #{bank.currency}"
  end

  def balance
    transactions_total = transactions.sum(:total)

    amount - transactions_total
  end
end
