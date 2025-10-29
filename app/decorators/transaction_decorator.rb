class TransactionDecorator < Draper::Decorator
  delegate_all
  decorates_association :sender
  decorates_association :receiver
  decorates_association :customer

  # Mantiene compatibilidad con vistas existentes
  def display_profit_margin
    return "0.0%" if object.rate.zero? || object.amount.zero?

    percentage = (object.profit / object.amount) * 100
    "#{percentage.round(4)}%"
  end

  def display_rate
    object.rate.to_s
  end

  def display_cost_rate
    object.cost_rate.to_s
  end

  def display_amount
    Money.new(object.amount, object.source_currency).format
  end

  def display_total
    Money.new(object.total, object.target_currency).format
  end

  def display_profit
    Money.new(object.profit, object.source_currency).format
  end

  # Métodos adicionales de presentación
  def rate_display
    "1 #{object.source_currency} = #{object.rate} #{object.target_currency}"
  end

  def currency_pair
    "#{object.source_currency}/#{object.target_currency}"
  end

  def formatted_created_at
    h.l(object.created_at, format: :long)
  end

  def status_badge
    return h.content_tag(:span, "Sin fondos", class: "badge badge-error") if object.bank_balance_transactions.empty?

    h.content_tag(:span, "Completada", class: "badge badge-success")
  end

  def profit_with_sign
    sign = object.profit.positive? ? "+" : ""
    "#{sign}#{display_profit}"
  end

  def profit_badge_class
    object.profit.positive? ? "badge-success" : "badge-error"
  end

  def funding_status
    return "Sin fondos" unless object.funded?
    return "Parcialmente financiada" unless object.fully_funded?

    "Completamente financiada"
  end

  def funding_percentage_formatted
    "#{object.funding_percentage.round(2)}%"
  end
end
