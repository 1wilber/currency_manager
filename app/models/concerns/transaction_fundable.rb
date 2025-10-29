# frozen_string_literal: true

module TransactionFundable
  extend ActiveSupport::Concern

  included do
    has_many :bank_balance_transactions, dependent: :destroy
    has_many :bank_balances, through: :bank_balance_transactions

    before_validation :assign_funds_to_transaction
    before_validation :set_cost_rate_from_balances

    validate :validate_sufficient_balance
  end

  # Asigna fondos automáticamente desde bank_balances disponibles
  # Implementa estrategia FIFO (First In, First Out)
  def assign_funds_to_transaction
    return if amount.blank? || rate.blank?
    return if total.blank? || total.zero?

    # Limpiar asignaciones previas
    bank_balance_transactions.destroy_all

    # Obtener balances disponibles ordenados por fecha (FIFO)
    balances = Bank.ves_default.bank_balances.with_balance.order(:created_at)
    balance_needed = total
    available_balance = balances.sum(:available_amount)

    Rails.logger.info "Asignando fondos: Disponible=#{available_balance}, Necesario=#{balance_needed}"

    # Validar fondos suficientes
    unless available_balance >= total
      errors.add(:base, I18n.t("errors.messages.not_enough_balance"))
      return
    end

    # Asignar fondos desde cada balance disponible
    balances.each do |bank_balance|
      break if balance_needed <= 0

      # Calcular cuánto se puede usar de este balance
      amount_to_use = [ balance_needed, bank_balance.available_amount ].min

      # Crear la asociación con amount_used y rate_used
      bank_balance_transactions.build(
        bank_balance: bank_balance,
        amount_used: amount_to_use,
        rate_used: bank_balance.rate
      )

      balance_needed -= amount_to_use
    end
  end

  # Calcula la tasa de costo promedio ponderada desde los bank_balances asignados
  # Usa un weighted average basado en amount_used y rate_used
  def merged_rates
    return 0.0 if bank_balance_transactions.empty?

    total_amount_used = BigDecimal("0")
    weighted_sum = BigDecimal("0")

    bank_balance_transactions.each do |bbt|
      amount_used = BigDecimal(bbt.amount_used.to_s)
      rate_used = BigDecimal(bbt.rate_used.to_s)

      total_amount_used += amount_used
      weighted_sum += (amount_used * rate_used)
    end

    return 0.0 if total_amount_used.zero?

    (weighted_sum / total_amount_used).to_f
  end

  # Establece el cost_rate desde el promedio ponderado de las tasas
  def set_cost_rate_from_balances
    return if bank_balance_transactions.empty?

    self.cost_rate = merged_rates
  end

  # Valida que haya suficiente balance asignado
  def validate_sufficient_balance
    return if total.blank? || total.zero?

    assigned_balance = bank_balance_transactions.sum { |bbt| bbt.amount_used || 0 }

    if assigned_balance < total
      errors.add(:base, I18n.t("errors.messages.not_enough_balance"))
    end
  end

  # Verifica si la transacción tiene fondos asignados
  def funded?
    bank_balance_transactions.any?
  end

  # Retorna el total de fondos asignados
  def total_funds_assigned
    bank_balance_transactions.sum(:amount_used)
  end

  # Retorna el porcentaje de fondos asignados vs el total necesario
  def funding_percentage
    return 0.0 if total.zero?

    (total_funds_assigned / total) * 100
  end

  # Información detallada de los fondos asignados
  def funding_details
    bank_balance_transactions.map do |bbt|
      {
        bank_balance_code: bbt.bank_balance.code,
        amount_used: bbt.amount_used,
        rate_used: bbt.rate_used,
        percentage: (bbt.amount_used / total) * 100
      }
    end
  end

  # Libera los fondos asignados (útil para cancelaciones)
  def release_funds!
    bank_balance_transactions.destroy_all
  end

  # Reasigna los fondos (útil cuando cambian los montos)
  def reassign_funds!
    release_funds!
    assign_funds_to_transaction
  end
end
