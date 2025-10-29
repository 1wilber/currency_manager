class AddInitialAndAvailableAmountToBankBalances < ActiveRecord::Migration[8.0]
  def change
    add_column :bank_balances, :available_amount, :float, default: 0.0
  end
end
