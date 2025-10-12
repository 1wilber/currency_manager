class BanksController < ApplicationController
before_action :set_bank, only: [ :show ]

  def index
    @collection = Bank.includes(:outgoings, :incomings).all
  end

  def show
  end

  private

  def set_bank
    @bank = Bank.includes(:outgoings, :incomings).find(params[:id])
  end
end
