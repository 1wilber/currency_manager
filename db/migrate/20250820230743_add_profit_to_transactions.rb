class AddProfitToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :profit, :float, default: 0.0
  end
end
