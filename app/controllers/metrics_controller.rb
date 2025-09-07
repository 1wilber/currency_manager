class MetricsController < ApplicationController
  def index
    date = Date.new(2025, 8, 1)
    @collection = Transaction.where(created_at: date.beginning_of_month..date.end_of_month)
  end
end
