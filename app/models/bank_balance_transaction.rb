class BankBalanceTransaction < ApplicationRecord
  belongs_to :bank_balance
  belongs_to :order, class_name: "Transaction", foreign_key: "transaction_id"
end
