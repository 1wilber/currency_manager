class BanksController < ApplicationController
before_action :set_bank, only: [ :show ]

  def index
    @collection = Bank.includes(:incomings).all
  end

  def show
    @transactions = @bank.incomings.recents.where(source_currency: current_exchange_rate.source, target_currency: current_exchange_rate.target)
    @total_profit = @transactions.sum(:profit)
  end

  private

  def set_bank
    @bank = Bank.includes(:incomings).find(params[:id]).decorate
  end
end
