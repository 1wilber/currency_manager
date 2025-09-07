class TransactionsController < ApplicationController
  before_action :set_sender, :set_receiver, only: [ :new, :edit ]
  has_scope :by_created_at, only: [ :index ]

  def index
    params[:by_created_at] ||= Time.zone.now.strftime("%Y-%m-%d")

    @collection = apply_scopes(Transaction).order(id: :desc)
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
end
