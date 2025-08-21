class Transaction < ApplicationRecord
  belongs_to :customer
  before_save :set_total_and_profit

  def display_amount
    Money.new(amount, source_currency)
  end

  def display_total
    Money.new(total, target_currency)
  end

  def display_profit
    Money.new(profit, source_currency)
  end

  def calculate_total
    (amount * rate)
  end

  def calculate_profit
    # Ganancia en source_currency (CLP)
    # Unidades de target_currency que se entregan
    target_units = amount / rate
    # Ganancia por unidad en source_currency
    profit_per_unit = rate - cost_rate
    # Ganancia total en source_currency
    (profit_per_unit * target_units).round(2)
  end

  def profit_margin
    return 0.0 if rate == 0 || amount == 0

    # Porcentaje de ganancia sobre el monto total recibido
    (calculate_profit / amount * 100).round(2)
  end

  private

  def set_total_and_profit
    self.total = calculate_total
    self.profit = calculate_profit
  end
end
