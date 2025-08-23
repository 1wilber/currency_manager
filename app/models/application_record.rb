class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class << self
    def has_currency_fields(*fields)
      fields.each do |field|
        define_method("#{field}=") do |value|
          self[field] = value.is_a?(String) ? to_delocalized_decimal(value) : value
        end
      end
    end
  end

  def to_delocalized_decimal(value)
    val = value.gsub(/\./, "").gsub(/\,/, ".")
    val
  end
end
