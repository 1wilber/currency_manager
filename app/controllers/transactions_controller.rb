class TransactionsController < ApplicationController
  include ButtonHelper
  include MoneyHelper
  before_action :set_date_range, only: [ :index ]
  has_scope :by_source_currency, only: [ :index ]
  has_scope :by_target_currency, only: [ :index ]

  helper :transactions

  def index
    params[:by_source_currency] ||= current_exchange_rate.source
    params[:by_target_currency] ||= current_exchange_rate.target

    @collection = apply_scopes(Transaction.preload(:sender, :receiver)).by_range(@date_range).order(id: :desc)
    @total_amount = Money.new(@collection.sum(:amount), current_exchange_rate.source).format(symbol: "$")
    @total_profit = Money.new(@collection.sum(:profit), current_exchange_rate.source).format(symbol: "$")
    @total = Money.new(@collection.sum(:total), current_exchange_rate.target).format(symbol: "$")
  end

  def new
    @record = model_class.new
  end

  def create
    @record = Transaction.new(transaction_params)

    if @record.save
      respond_to do |format|
        format.html { redirect_to transactions_path }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @record.update(transaction_params)
      respond_to do |format|
        format.html { redirect_to transactions_path }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def calculate
    @transaction = model_class.new
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

  def model_class
    Transaction
  end

  private

  def transaction_params
    params.require(:transaction).permit(
      :sender_type,
      :sender_id,
      :receiver_type,
      :receiver_id,
      :amount,
      :source_currency,
      :target_currency,
      :rate,
      :cost_rate,
      :profit,
      :total,
    )
  end

  def set_record
    @record = if [ :edit, :update ].include?(action_name.to_sym)
      model_class.find(params[:id])
    else
      @last_transaction = model_class.last
      if @last_transaction.present?
        params[:sender_type] ||= @last_transaction.sender_type
        params[:sender_id] ||= @last_transaction.sender_id
        model_class.new(
          rate: @last_transaction.rate,
          cost_rate: @last_transaction.cost_rate,
          source_currency: @last_transaction.source_currency,
        )
      end
    end
  end


  def set_date_range
    @date_range = params[:by_range].present? ? params[:by_range].to_date : Date.today
  end
end
