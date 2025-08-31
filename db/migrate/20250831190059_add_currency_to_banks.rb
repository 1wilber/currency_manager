class AddCurrencyToBanks < ActiveRecord::Migration[8.0]
  def change
    add_column :banks, :currency, :string, null: false, default: "CLP"
  end
end
