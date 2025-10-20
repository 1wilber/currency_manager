class BankBalance < ApplicationRecord
  belongs_to :bank
  has_many :bank_balance_transactions, dependent: :destroy
  has_many :transactions, through: :bank_balance_transactions, source: :order

  def code
    "COM-#{id.to_s.rjust(3, '0')}"
  end

  def display_name
    "Saldo: #{balance} #{bank.currency} - 1 CLP = #{rate} #{bank.currency}"
  end

  def balance
    transactions_total = transactions.sum(:total)

    amount - transactions_total
  end

  def percentage_used
    return 0 if amount.zero?
    ((amount - balance) / amount * 100).round(2)
  end
end
