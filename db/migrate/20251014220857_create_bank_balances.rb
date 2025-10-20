class CreateBankBalances < ActiveRecord::Migration[8.0]
  def change
    create_table :bank_balances do |t|
      t.references :bank, null: false, foreign_key: true

      t.float :amount, default: 0.0
      t.float :rate, default: 0.0
      t.text :description



      t.timestamps
    end
  end
end
