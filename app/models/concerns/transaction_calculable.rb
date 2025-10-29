# frozen_string_literal: true

module TransactionCalculable
  extend ActiveSupport::Concern

  included do
    before_validation :calculate_amounts
  end

  # Calcula el total de la transacción
  # Formula: total = amount * rate
  def calculate_total
    self.total = (amount * rate)
  end

  # Calcula la ganancia de la transacción
  # Formula: profit = ((amount * cost_rate) - total) / rate
  def calculate_profit
    cost_total = (amount * cost_rate)
    calculate_total

    result = ((cost_total - total) / rate).round(2)
    self.profit = result.nan? ? 0 : result
  end

  # Calcula total y ganancia
  def calculate_amounts
    return unless amount && rate && cost_rate

    calculate_total
    calculate_profit
  end

  # Calcula el margen de ganancia como porcentaje
  # Retorna el valor decimal (no el porcentaje formateado)
  def profit_margin
    return 0.0 if rate.zero? || amount.zero?

    (profit / amount)
  end

  # Calcula el porcentaje de ganancia en relación al total
  def profit_percentage_on_total
    return 0.0 if total.zero?

    (profit / total) * 100
  end

  # Calcula la diferencia entre la tasa de costo y la tasa de venta
  def rate_spread
    rate - cost_rate
  end

  # Verifica si la transacción es rentable
  def profitable?
    profit.positive?
  end

  # Calcula el total del costo
  def cost_total
    amount * cost_rate
  end
end
