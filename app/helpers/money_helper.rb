module MoneyHelper
  include ActionView::Helpers::NumberHelper
  def max_precision
    10
  end

  def money_as_value(amount, precision: 10)
    begin
    number_to_currency(
                        amount,
                        unit: "",
                        precision:,
                      ).strip
    end
  end
end
