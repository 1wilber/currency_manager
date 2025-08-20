class Transaction < ApplicationRecord
  belongs_to :customer
  before_save :set_total_and_profit

  def calculate_total
    (amount * rate)
  end

  def calculate_profit
    ((rate - cost_rate) * amount)
  end

  def profit_margin
    return 0.0 if rate == 0

    profit / rate * 100
  end

  private

  def set_total_and_profit
    self.total = calculate_total
    self.profit = calculate_profit
  end
end
