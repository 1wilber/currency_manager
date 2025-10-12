class AddCustomerToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :customer, null: false, foreign_key: true
  end
end
