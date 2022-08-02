# frozen_string_literal: true

module EnvControl
  class ValidateEnvContract

    def call(contract:)
      contract.each_pair do |env_var_name, env_var_contract|
        @env_var = env_var_name
        validate_key!(env_var_name)
        if env_var_contract.is_a?(Hash)
          validate_environment_specific_contract!(env_var_contract)
        else
          validate_contract!(env_var_contract)
        end
      end
    end

    private

    attr_reader :env_var, :environment_name

    def validate_environment_specific_contract!(hash)
      raise_wrong_value!(hash) if hash.empty?
      hash.each_pair do |environment_name, contract|
        unless environment_name.is_a?(String)
          raise NonStringEnvironmentNameError.new(context: {environment_name: environment_name, env_var: env_var})
        end
        @environment_name = environment_name
        validate_contract!(contract)
      end
      @environment = nil
    end

    def validate_contract!(value)
      if value.is_a?(Array)
        raise_wrong_value!(value) if value.empty?
        value.each { |subvalue| validate_value!(subvalue) }
      else
        validate_value!(value)
      end
    end

    def validate_key!(key)
      return if key.is_a?(Symbol)

      raise NonSymbolicKeyError.new(context: { key: key, env_var: env_var })
    end

    def validate_value!(value)
      if [Symbol, String, NilClass].include?(value.class) || value.respond_to?(:call)
        true
      else
        raise_wrong_value!(value)
      end
    end

    def raise_wrong_value!(value)
      raise WrongValueError.new context: { value: value, env_var: env_var, environment_name: environment_name }
    end
  end
end
