class BankBalanceTransaction < ApplicationRecord
  belongs_to :bank_balance
  belongs_to :order, class_name: "Transaction", foreign_key: "transaction_id"

  has_currency_fields :amount_used, :rate_used

  # Callback para actualizar available_amount del BankBalance al crear
  after_create :update_bank_balance_available_amount

  # Callback para liberar available_amount del BankBalance al eliminar
  after_destroy :release_bank_balance_amount

  private

  def update_bank_balance_available_amount
    return if amount_used.zero?

    bank_balance.consume_amount(amount_used)
  end

  def release_bank_balance_amount
    return if amount_used.zero?

    bank_balance.release_amount(amount_used)
  end
end
