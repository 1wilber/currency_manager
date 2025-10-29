# frozen_string_literal: true

module TransactionAttributable
  extend ActiveSupport::Concern

  included do
    belongs_to :sender, polymorphic: true
    belongs_to :receiver, polymorphic: true
    belongs_to :customer

    before_validation :set_currencies_from_parties
    before_validation :set_customer_from_receiver

    validates :source_currency, :target_currency, presence: true
    validate :validate_currency_difference
  end

  # Establece las monedas desde el sender y receiver
  def set_currencies_from_parties
    self.source_currency ||= sender&.currency
    self.target_currency ||= receiver&.currency
  end

  # Establece el customer desde el receiver si es un Customer
  def set_customer_from_receiver
    self.customer ||= receiver if receiver.is_a?(Customer)
  end

  # Valida que las monedas sean diferentes (opcional, según reglas de negocio)
  def validate_currency_difference
    return if source_currency.blank? || target_currency.blank?

    if source_currency == target_currency
      errors.add(:base, "Las monedas de origen y destino deben ser diferentes")
    end
  end

  # Verifica si la transacción involucra una moneda específica
  def involves_currency?(currency)
    source_currency == currency || target_currency == currency
  end

  # Retorna el par de monedas como string
  def currency_pair
    "#{source_currency}/#{target_currency}"
  end

  # Retorna información de las partes involucradas
  def parties_info
    {
      sender: {
        type: sender.class.name,
        name: sender_name,
        currency: source_currency
      },
      receiver: {
        type: receiver.class.name,
        name: receiver_name,
        currency: target_currency
      }
    }
  end

  # Nombre del remitente
  def sender_name
    sender.try(:name) || sender.try(:full_name) || "N/A"
  end

  # Nombre del receptor
  def receiver_name
    receiver.try(:name) || receiver.try(:full_name) || "N/A"
  end
end
