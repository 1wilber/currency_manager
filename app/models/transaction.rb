class Transaction < ApplicationRecord
  has_currency_fields :amount, :total, :profit, :rate, :cost_rate
  belongs_to :sender, polymorphic: true
  belongs_to :receiver, polymorphic: true

  before_save :set_total_and_profit

  with_options presence: true do
    validates :source_currency, :target_currency
  end

  def display_profit_margin
    "#{(profit_margin.round(4)) * 100}%"
  end

  def display_rate
    "1 #{source_currency} = #{rate} #{target_currency}"
  end

  def display_cost_rate
    "1 #{source_currency} = #{cost_rate} #{target_currency}"
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

  private

  def set_total_and_profit
    calculate_total
    calculate_profit
  end
end
