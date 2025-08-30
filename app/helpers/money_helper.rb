module MoneyHelper
  def max_precision
    10
  end

  def money_as_value(amount)
    begin
    number_to_currency(
                        amount,
                        unit: "",
                        precision: max_precision,
                      ).strip
    rescue StandardError
      ""
    end
  end
end
