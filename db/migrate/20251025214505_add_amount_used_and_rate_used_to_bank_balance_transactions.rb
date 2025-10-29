class AddAmountUsedAndRateUsedToBankBalanceTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :bank_balance_transactions, :amount_used, :float, default: 0.0
    add_column :bank_balance_transactions, :rate_used, :float, default: 0.0
  end
end
