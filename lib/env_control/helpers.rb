# frozen_string_literal: true

module EnvControl
  module Helpers

    def as_array(value)
      value.is_a?(Array) ? value : [value] # Wraps nil (in contrast to Array.wrap)
    end

    def environment_specific?(var_contract)
      var_contract.respond_to?(:has_key?)
    end

    def raise_error(klass)
      raise klass.new context: context
    end

  end
end
