class CreateBankBalanceTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :bank_balance_transactions do |t|
      t.references :bank_balance, null: false, foreign_key: true
      t.references :transaction, null: false, foreign_key: true

      t.timestamps
    end
  end
end
