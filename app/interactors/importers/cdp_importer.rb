require "roo"
require "pry"

module Importers
  class CdpImporter
    include Interactor

    delegate :file_path, to: :context

    def call
      fail!(error: I18n.t(:file_not_found)) unless File.exist?(file_path)


      xlsx = Roo::Excelx.new(file_path)
      basename = File.basename(file_path)
      creation_date, extension = basename.split(".")
      day, month, year = creation_date.split("-").map(&:to_i)

      created_at = Date.new(year, month, day)

      sheet = xlsx.sheet(0)
      sheet_data = []
      sheet.each(created_at: "Fecha", receiver_name: "Nombre", sender_name: "Otro Banco", amount: "Pesos Comprados", rate: "Tasa %", cost_rate: "Tasa Colombia") do |hash|
        next if hash[:amount].to_f.zero?  || hash[:receiver_name].nil?

        hash[:created_at] = created_at
        hash[:sender_name] =  hash[:sender_name].present? ? hash[:sender_name].strip.capitalize : "default"
        hash[:receiver_name] = hash[:receiver_name].strip.capitalize

        sheet_data << hash
      end

      return if sheet_data.empty?
      sender_names = sheet_data.map { |hash| hash[:sender_name] }.uniq
      receiver_names = sheet_data.map { |hash| hash[:receiver_name] }.uniq

      new_senders = build_senders(sender_names).map(&:save)
      new_receivers = build_receivers(receiver_names).map(&:save)
      Transaction.transaction do
        new_transactions = build_transactions(sheet_data, created_at).map(&:save)
      end
    end

    private

    def build_transactions(transactions, date)
      banks = Bank.all
      customers = Customer.all
      sender = Bank.ves_default

      transactions.map do |transaction|
        receiver = banks.find { |bank| bank.name == transaction[:sender_name] }
        customer = customers.find { |customer| customer.first_name == transaction[:receiver_name] }

        Transaction.new(
          sender:,
          receiver:,
          customer:,
          amount: transaction[:amount],
          rate: transaction[:rate],
          cost_rate: transaction[:cost_rate],
          source_currency: receiver.currency,
          target_currency: "VES",
          created_at: date
        )
      end
    end

    def build_senders(sender_names)
      bank_names = Bank.where(name: sender_names).pluck(:name)
      currency = "CLP"

      new_sender_names = sender_names.reject do |name|
        bank_names.include?(name)
      end

      new_sender_names.map do |name|
        Bank.new(name: name, currency:)
      end
    end

    def build_receivers(receiver_names)
      customer_names = Customer.where(first_name: receiver_names).pluck(:first_name)

      new_customers = receiver_names.reject do |name|
        customer_names.include?(name)
      end

      new_customers.map do |name|
        Customer.new(first_name: name)
      end
    end
  end
end
