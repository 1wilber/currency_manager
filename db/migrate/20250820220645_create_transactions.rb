class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.string :source_currency, null: false
      t.string :target_currency, null: false
      t.float :rate, default: 0.0, null: false
      t.float :cost_rate, default: 0.0, null: false
      t.float :amount, default: 0.0, null: false
      t.float :total, default: 0.0, null: false
      t.references :customer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
