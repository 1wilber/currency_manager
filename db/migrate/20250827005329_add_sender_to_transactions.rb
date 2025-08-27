class AddSenderToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :sender, polymorphic: true, null: false
    add_reference :transactions, :receiver, polymorphic: true, null: false
  end
end
