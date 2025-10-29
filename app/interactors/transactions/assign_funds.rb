# frozen_string_literal: true

module Transactions
  # Interactor para asignar fondos de bank_balances a una transacción
  # Implementa una estrategia FIFO (First In, First Out)
  #
  # @example
  #   result = Transactions::AssignFunds.call(transaction: transaction)
  #   if result.success?
  #     puts "Fondos asignados: #{result.assigned_balances.count}"
  #   else
  #     puts "Error: #{result.error}"
  #   end
  class AssignFunds
    include Interactor

    delegate :transaction, to: :context

    # Ejecuta la asignación de fondos
    def call
      validate_transaction!
      clear_existing_assignments!

      available_balances = fetch_available_balances
      validate_sufficient_funds!(available_balances)

      assign_balances_to_transaction(available_balances)

      context.assigned_balances = transaction.bank_balance_transactions
      context.total_assigned = transaction.bank_balance_transactions.sum(&:amount_used)
    rescue InsufficientFundsError => e
      context.fail!(error: e.message)
    rescue StandardError => e
      context.fail!(error: "Error al asignar fondos: #{e.message}")
    end

    private

    def validate_transaction!
      context.fail!(error: "Transacción inválida") if transaction.blank?
      context.fail!(error: "Total de transacción no calculado") if transaction.total.blank? || transaction.total.zero?
    end

    def clear_existing_assignments!
      transaction.bank_balance_transactions.destroy_all
    end

    def fetch_available_balances
      Bank.ves_default
          .bank_balances
          .with_balance
          .order(:created_at)
    end

    def validate_sufficient_funds!(balances)
      available_balance = balances.sum(:available_amount)
      balance_needed = transaction.total

      Rails.logger.info "Asignando fondos: Disponible=#{available_balance}, Necesario=#{balance_needed}"

      if available_balance < balance_needed
        raise InsufficientFundsError, I18n.t("errors.messages.not_enough_balance")
      end
    end

    def assign_balances_to_transaction(balances)
      balance_needed = transaction.total

      balances.each do |bank_balance|
        break if balance_needed <= 0

        amount_to_use = calculate_amount_to_use(bank_balance, balance_needed)

        create_balance_transaction(bank_balance, amount_to_use)

        balance_needed -= amount_to_use
      end
    end

    def calculate_amount_to_use(bank_balance, balance_needed)
      [ balance_needed, bank_balance.available_amount ].min
    end

    def create_balance_transaction(bank_balance, amount_to_use)
      transaction.bank_balance_transactions.build(
        bank_balance: bank_balance,
        amount_used: amount_to_use,
        rate_used: bank_balance.rate
      )
    end

    # Excepción personalizada para fondos insuficientes
    class InsufficientFundsError < StandardError; end
  end
end
