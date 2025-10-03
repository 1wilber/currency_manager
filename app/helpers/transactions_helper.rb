module TransactionsHelper
    def prev_day_url
      transactions_path(by_range: @date_range - 1.day)
    end

    def today_url
      transactions_path(by_range: Date.today)
    end

    def next_day_url
      transactions_path(by_range: @date_range + 1.day)
    end

    def current_day_url
      transactions_path(by_range: @date_range)
    end
end
