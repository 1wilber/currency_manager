class RemoveCustomerFromTransactions < ActiveRecord::Migration[8.0]
  def change
    remove_column :transactions, :customer_id
  end
end
