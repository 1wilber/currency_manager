class BankBalance < ApplicationRecord
  belongs_to :bank
  has_many :bank_balance_transactions, dependent: :destroy
  has_many :transactions, through: :bank_balance_transactions, source: :order
  has_currency_fields :amount, :rate, :initial_amount, :available_amount

  alias_attribute :initial_amount, :amount
  # Callback para inicializar available_amount cuando se crea un nuevo saldo
  before_create :initialize_available_amount

  scope :with_balance, -> do
    where("bank_balances.available_amount > 0")
  end

  def code
    "COM-#{id.to_s.rjust(3, '0')}"
  end

  def display_name
    "Saldo: #{balance} #{bank.currency} - 1 CLP = #{rate} #{bank.currency}"
  end

  # Balance ahora es igual a available_amount
  def balance
    available_amount || 0.0
  end

  # Monto total usado por transacciones
  def amount_used
    bank_balance_transactions.sum(:amount_used)
  end

  def percentage_used
    return 0 if initial_amount.zero?
    ((initial_amount - available_amount) / initial_amount * 100).round(2)
  end

  # Método para consumir parte del saldo disponible
  # Retorna true si hay suficiente saldo, false en caso contrario
  def consume_amount(amount_to_consume)
    return false if available_amount < amount_to_consume

    self.available_amount -= amount_to_consume
    save
  end

  # Método para liberar saldo (por ejemplo, al eliminar una transacción)
  def release_amount(amount_to_release)
    self.available_amount += amount_to_release
    save
  end

  private

  def initialize_available_amount
    self.available_amount = initial_amount
  end
end
