# frozen_string_literal: true

module EnvControl
  class ValidateEnvVariable

    def call(name, value, contract)
      raise ArgumentError unless [String, NilClass].include?(value.class)

      [contract].flatten.each do |validator|
        return true if satisfies?(name, value, validator)
      end
      false
    end

    private

    def satisfies?(name, value, validator)
      case validator
      when NilClass
        value.nil?
      when String
        value == validator
      when Regexp
        value.match?(validator)
      when Symbol
        run_validator(validator, name, value)
      else
        raise "unknown validator type: #{validator.inspect}" unless validator.respond_to?(:call)
        run_callable_validator(validator, name, value)
      end
    end

    def run_callable_validator(validator, name, value)
      return false if value.nil?

      validator.call(value)
    end

    def run_validator(validator, name, value)
      unless library.respond_to?(validator)
        raise "unknown validator #{validator.inspect} for #{name} variable"
      end

      if value.nil?
        return EnvControl.configuration.validators_allowing_nil.include?(validator) ? true : false
      end

      library.send(validator, value)
    end

    def library
      @library ||= EnvControl::Validators
    end

  end
end