class MetricsController < ApplicationController
  def index
    @date = Date.new(2025, 8, 1)
    @collection = Transaction.where(created_at: @date.beginning_of_month..@date.end_of_month)

    @transactions_per_day = @collection.group(:created_at).count
    @transactions_per_day_avg = (@transactions_per_day.values.sum / @transactions_per_day.size).round(2)
    @transactions_profit = Money.new(@collection.sum(:profit), "CLP").format(symbol: "$")
  end
end
