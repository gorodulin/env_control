# frozen_string_literal: true

module EnvControl
  class ValidateEnvContract
    include Helpers

    def call(contract:, environment_name:)
      contract.each_pair do |var_name, var_contract|
        @context = { var_name: var_name, var_contract: var_contract, environment: environment_name }

        validate_variable_name!
        unless environment_specific?(var_contract)
          validate_contract!(var_contract)
        else
          validate_environment_specific_contract!
        end
      end
    end

    private

    attr_reader :context

    def validate_contract!(var_contract)
      as_array(var_contract).tap do |contract|
        raise_error EmptyContractError if contract.empty?
        contract.each { |validator| validate_validator_type!(validator) }
      end
    end

    def validate_validator_type!(validator)
      context[:var_validator] = validator
      unless [Symbol, String, Regexp, NilClass].include?(validator.class) || validator.respond_to?(:call)
        raise_error WrongValidatorTypeError
      end
    end

    def validate_environment_specific_contract!
      contracts = context[:var_contract]
      environment = context[:environment]
      raise_error EmptyEnvironmentNameError unless context[:environment]
      raise_error EmptyContractError if contracts.empty?
      raise_error NonStringEnvironmentNameError unless contracts.keys.all? { _1.is_a?(String) }
      raise_error MissingEnvironmentError unless environment_specific_contract_exists?
      contracts.each_pair do |environment_name, contract|
        validate_contract!(contract)
      end
    end

    def environment_specific_contract_exists?
      context[:var_contract].has_key?(context[:environment]) || context[:var_contract].has_key?("default")
    end

    def validate_variable_name!
      return if context[:var_name].is_a?(Symbol)

      raise_error NonSymbolicKeyError
    end

  end
end
