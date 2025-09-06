class TransactionsController < ApplicationController
  def index
    @collection = Transaction.all
  end
end
