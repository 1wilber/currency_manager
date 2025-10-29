class Transaction < ApplicationRecord
  has_currency_fields :amount, :total, :profit, :rate, :cost_rate

  has_many :bank_balance_transactions, dependent: :destroy
  has_many :bank_balances, through: :bank_balance_transactions

  belongs_to :sender, polymorphic: true
  belongs_to :receiver, polymorphic: true
  belongs_to :customer

  validate :validate_balance
  # validates :bank_balance_transactions, presence: true

  before_validation :set_currencies,
                    :set_customer,
                    :calculate,
                    :assign_funds!,
                    :set_cost_rate

  scope :total, -> { sum(:total) }
  scope :recents, -> { order(id: :desc) }

  def set_currencies
    self.source_currency ||= sender.try(:currency)
    self.target_currency ||= receiver.try(:currency)
  end

  def set_customer
    self.customer ||= receiver
  end

  scope :by_range, ->(range) do
    from, to = range
    to ||= from.end_of_day
    where(created_at: from.beginning_of_day..to.end_of_day)
  end

  scope :by_target_currency, ->(currency) do
    where(target_currency: currency)
  end

  scope :by_source_currency, ->(currency) do
    where(source_currency: currency)
  end

  before_save :calculate

  with_options presence: true do
    validates :source_currency, :target_currency
  end

  def display_profit_margin
    "#{(profit_margin.round(4)) * 100}%"
  end

  def display_rate
    # "1 #{source_currency} = #{rate} #{target_currency}"
    rate.to_s
  end

  def display_cost_rate
    cost_rate.to_s
  end

  def display_amount
    Money.new(amount, source_currency).format
  end

  def display_total
    Money.new(total, target_currency).format
  end

  def display_profit
    Money.new(profit, source_currency).format
  end

  def calculate_total
    self.total = (amount * rate)
  end

  def calculate_profit
    # target_units = amount / rate
    # profit_per_unit = rate - cost_rate
    # (profit_per_unit * target_units).round(2)
    cost_total = (amount * cost_rate)
    calculate_total

    result = ((cost_total - total) / rate).round(2)
    self.profit = result.nan? ? 0 : result
  end

  def profit_margin
    return 0.0 if rate == 0 || amount == 0

    # Porcentaje de ganancia sobre el monto total recibido
    (calculate_profit / amount)
  end

  def calculate
    calculate_total
    calculate_profit
  end

  def assign_funds!
    bank_balance_transactions.destroy_all
    balances = Bank.ves_default.bank_balances.with_balance.order(:created_at)
    balance_needed = total
    available_balance = balances.sum(:available_amount)
    puts "Available Balance: #{available_balance}, Balance Needed: #{balance_needed}"
    return errors.add(:base, I18n.t("errors.messages.not_enough_balance")) unless available_balance >= total

    bank_balance_transactions = balances.map do |bank_balance|
      next if balance_needed <= 0

      # Calcular cuánto se puede usar de este balance
      amount_to_use = [ balance_needed, bank_balance.available_amount ].min

      balance_needed -= amount_to_use
      # Crear la asociación con amount_used y rate_used
      self.bank_balance_transactions.build(
        bank_balance: bank_balance,
        amount_used: amount_to_use,
        rate_used: bank_balance.rate
      )
    end
  end

  def merged_rates
    amounts_used = []
    totals = bank_balance_transactions.map do |bank_balance_transaction|
      amounts_used << bank_balance_transaction.amount_used
      bank_balance_transaction.amount_used * bank_balance_transaction.rate_used
    end
    return 0.0 if amounts_used.empty?

    totals.sum / amounts_used.sum
  end

  private
  def set_cost_rate
    self.cost_rate = merged_rates
  end

  def validate_balance
    # Calcular el balance disponible total de los bank_balances asignados
    available_balance = bank_balance_transactions.sum { |bbt| bbt.amount_used || 0 }

    errors.add(:base, I18n.t("errors.messages.not_enough_balance")) unless available_balance >= total
  end
end
