module Madmin
  module ResourceOverrides
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def friendly_name
        model.model_name.human(count: 2)
      end
    end
  end
end
