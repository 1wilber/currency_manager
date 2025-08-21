class TransactionResource < Madmin::Resource
  # Attributes
  attribute :id, form: false, index: true
  attribute :source_currency, :select, index: true, collection: Rails.application.config.available_currencies
  attribute :target_currency, :select, index: true, collection: Rails.application.config.available_currencies
  attribute :rate, :string, index: true
  attribute :cost_rate, :string, index: true
  attribute :amount, field: CurrencyField, index: true
  attribute :total, field: CurrencyField, index: true
  attribute :profit, index: true
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Associations
  attribute :customer

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
