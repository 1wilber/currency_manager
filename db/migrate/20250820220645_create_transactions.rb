class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.string :source_currency, null: false
      t.string :target_currency, null: false
      t.decimal :rate, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :cost_rate, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :amount, default: 0, null: false
      t.integer :total, default: 0, null: false
      t.references :customer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
