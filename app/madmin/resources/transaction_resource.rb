class TransactionResource < Madmin::Resource
  include Madmin::ResourceOverrides
  # Attributes
  attribute :id, form: false, index: true
  # Associations
  attribute :sender_id, :select, form: true, collection: Bank.all.map { |bank| [ bank.display_name, bank.id ] }
  attribute :receiver_id, :select, form: true, collection: Customer.all.map { |customer| [ customer.name, customer.id ] }
  attribute :sender_type
  attribute :receiver_type

  attribute :source_currency, :select, collection: Rails.application.config.available_currencies, show: false
  attribute :target_currency, :select, collection: Rails.application.config.available_currencies, show: false

  attribute :rate, field: CurrencyField, index: true
  attribute :cost_rate, field: CurrencyField, index: true
  attribute :amount, field: CurrencyField, index: true
  attribute :total, field: CurrencyField, index: true, form: false
  attribute :profit, field: CurrencyField, index: true, form: false
  attribute :created_at, field: LocalTimeField, form: false, index: true
  attribute :updated_at, field: LocalTimeField, form: false


  # Add scopes to easily filter records
  # scope :published

  # Add actions to the resource's show page
  # member_action do |record|
  #   link_to "Do Something", some_path
  # end

  # Customize the display name of records in the admin area.
  # def self.display_name(record) = record.name

  # Customize the default sort column and direction.
  # def self.default_sort_column = "created_at"
  #
  # def self.default_sort_direction = "desc"
end
