# frozen_string_literal: true

class Transaction < ApplicationRecord
  include TransactionAttributable
  include TransactionCalculable
  include TransactionFundable

  # Money fields configuration
  has_currency_fields :amount, :total, :profit, :rate, :cost_rate

  # ============================================================================
  # SCOPES
  # ============================================================================

  scope :recents, -> { order(id: :desc) }
  scope :oldest_first, -> { order(:created_at) }

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

  scope :profitable, -> { where("profit > 0") }
  scope :non_profitable, -> { where("profit <= 0") }

  scope :with_sender_type, ->(type) do
    where(sender_type: type)
  end

  scope :with_receiver_type, ->(type) do
    where(receiver_type: type)
  end

  scope :for_customer, ->(customer) do
    where(customer: customer)
      .or(where(sender: customer))
      .or(where(receiver: customer))
  end

  scope :for_bank, ->(bank) do
    where(sender: bank).or(where(receiver: bank))
  end

  # ============================================================================
  # CLASS METHODS
  # ============================================================================

  # Suma total de todas las transacciones en el scope
  def self.total_amount
    sum(:total)
  end

  # Suma total de ganancias
  def self.total_profit
    sum(:profit)
  end

  # Promedio de tasa
  def self.average_rate
    average(:rate)
  end

  # Estadísticas del scope actual
  def self.statistics
    {
      count: count,
      total_amount: sum(:total),
      total_profit: sum(:profit),
      average_rate: average(:rate),
      average_profit_margin: average("profit / NULLIF(amount, 0)")
    }
  end

  # Agrupa transacciones por moneda
  def self.group_by_currency_pair
    group(:source_currency, :target_currency)
      .select(
        :source_currency,
        :target_currency,
        "COUNT(*) as count",
        "SUM(total) as total_sum",
        "SUM(profit) as total_profit",
        "AVG(rate) as avg_rate"
      )
  end

  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================

  # Verifica si la transacción está completamente financiada
  def fully_funded?
    funded? && total_funds_assigned >= total
  end

  # Verifica si la transacción es válida para ser guardada
  def ready_to_save?
    valid? && fully_funded?
  end

  # Información completa de la transacción
  def summary
    {
      id: id,
      currency_pair: currency_pair,
      amount: amount,
      rate: rate,
      cost_rate: cost_rate,
      total: total,
      profit: profit,
      profit_margin: profit_margin,
      sender: sender_name,
      receiver: receiver_name,
      funded: funded?,
      funding_percentage: funding_percentage,
      created_at: created_at
    }
  end

  # Duplica la transacción (útil para transacciones recurrentes)
  def duplicate
    self.class.new(
      sender: sender,
      receiver: receiver,
      customer: customer,
      amount: amount,
      rate: rate,
      source_currency: source_currency,
      target_currency: target_currency
    )
  end

  # Información para auditoría
  def audit_info
    {
      transaction_id: id,
      created_at: created_at,
      parties: parties_info,
      amounts: {
        amount: amount,
        rate: rate,
        cost_rate: cost_rate,
        total: total,
        profit: profit,
        profit_margin: "#{(profit_margin * 100).round(2)}%"
      },
      funding: funding_details
    }
  end

  private

  # Callback adicional para logging (opcional)
  def log_transaction_creation
    Rails.logger.info "Transaction created: #{summary.to_json}"
  end
end
