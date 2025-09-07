class TransactionsController < ApplicationController
  before_action :set_sender, :set_receiver, only: [ :new, :edit ]
  before_action :set_date_range, only: [ :index ]
  has_scope :by_source_currency, only: [:index]
  has_scope :by_target_currency, only: [:index]

  def index
    params[:by_source_currency] ||= current_exchange_rate.source
    params[:by_target_currency] ||= current_exchange_rate.target

    @collection = apply_scopes(Transaction.preload(:sender, :receiver)).by_range(@date_range).order(id: :desc)
    @total_amount = Money.new(@collection.sum(:amount), current_exchange_rate.source).format(symbol: "$")
    @total_profit = Money.new(@collection.sum(:profit), current_exchange_rate.source).format(symbol: "$")
    @total = Money.new(@collection.sum(:total), current_exchange_rate.target).format(symbol: "$")
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
      :rate_cost,
      :profit,
      :total,
    )
  end

  def set_sender
    sender_type = params[:sender_type]
    sender_id = params[:sender_id]
    return @sender = @record.sender if @record.persisted?
    return if sender_type.blank? || sender_id.blank?

    @sender = sender_type.constantize.find(params[:sender_id])
  end

  def set_receiver
    receiver_type = params[:receiver_type]
    receiver_id = params[:receiver_id]

    return @receiver = @record.receiver if @record.persisted?
    return if receiver_type.blank? || receiver_id.blank?

    @receiver = receiver_type.constantize.find(params[:receiver_id])
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
    @date_range = if params[:by_range].present?
      params[:by_range].split("a").map(&:strip).map(&:to_date)
    else
      @date_range = [Date.today, Date.today]
    end
  end
end
