class BankTransactionsController < ApplicationController
  before_action :set_bank

  def create
    @transaction = @bank.incomings.create!(transaction_params)

    if @transaction.errors.any?
      render @bank, status: :unprocessable_entity
    else
      redirect_to bank_path(@bank, type: :incomings)
    end
  end

  private

  def set_bank
    @bank = Bank.find(params[:bank_id])
  end
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
end
