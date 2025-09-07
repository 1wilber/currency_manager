module Madmin
  class TransactionsController < Madmin::ResourceController
    include ActionView::Helpers::NumberHelper
    include MoneyHelper

    helper_method :money_value

    skip_before_action :set_record, only: [ :calculate ]
    before_action :set_sender, only: [ :new ]
    before_action :set_current_date, only: [ :index ]

    def calculate
      amount = params.dig(:amount) || 0
      rate = params.dig(:rate) || 0
      cost_rate = params.dig(:cost_rate) || 0

      @transaction = Transaction.new(amount:, rate:, cost_rate:)

      if amount.present?
        @transaction.calculate_profit
        @transaction.calculate_total
      end

      result = {
        amount: money_as_value(@transaction.amount),
        profit: money_as_value(@transaction.profit),
        total: money_as_value(@transaction.total)
      }

      respond_to do |format|
        format.json { render json: result }
      end
    end

    def money_value(arg)
      money_as_value(arg)
    end

    private

    def set_current_date
      puts params[:by_created_at]
    end

    def sender_id
      resource_params.dig(:sender_id)
    end

    def set_sender
      return if (resource_params rescue {}).blank?
      return if resource_params.dig(:sender_id).blank?

      @sender = resource_params.dig(:sender_type).constantize.find(sender_id)
    end
  end
end
