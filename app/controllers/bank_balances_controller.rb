class BankBalancesController < ApplicationController
  before_action :set_bank, only: [ :create ]

  def index
    @bank_balances = BankBalance.includes(:bank).all
  end

  def create
    @bank_balance = @bank.bank_balances.new(bank_balance_params)

    if @bank_balance.save
      redirect_to bank_path(@bank), notice: "Saldo creado exitosamente."
    else
      redirect_to bank_path(@bank), alert: "Error al crear el saldo: #{@bank_balance.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_bank
    @bank = Bank.find(params[:bank_id])
  end

  def bank_balance_params
    params.require(:bank_balance).permit(:amount, :rate, :description)
  end
end
