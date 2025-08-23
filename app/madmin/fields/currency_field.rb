class CurrencyField < Madmin::Field
  def value(record)
    currency_method = "display_#{attribute_name}"
    if record.respond_to?(currency_method)
      record.public_send(currency_method)
    else
      record.send(attribute_name)
    end
  end

  # def to_partial_path(name)
  #   unless %w[index show form].include? name
  #     raise ArgumentError, "`partial` must be 'index', 'show', or 'form'"
  #  end
  #
  #   "/madmin/fields/#{self.class.field_type}/#{name}"
  # end

  # def to_param
  #   attribute_name
  # end

  # # Used for checking visibility of attribute on an view
  # def visible?(action, default: true)
  #   options.fetch(action.to_sym, default)
  # end

  # def required?
  #   model.validators_on(attribute_name).any? { |v| v.is_a? ActiveModel::Validations::PresenceValidator }
  # end
end
