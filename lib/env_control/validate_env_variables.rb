# frozen_string_literal: true

module EnvControl
  class ValidateEnvVariables

    def call(contract:, env:, environment_name:)
      failures = {}
      contract.each do |env_var, var_contracts|
        if environment_specific?(var_contracts)
          var_contract = GetEnvironmentSpecificContract.new.call(env_var: env_var, contracts: var_contracts, environment_name: environment_name)
        else
          var_contract = as_array(var_contracts)
        end
        next unless var_contract # No environment-specific contract found
        var_value = env.fetch(env_var.to_s, nil)
        next if contract_honoured?(env_var, var_value, var_contract)

        failures[env_var] = var_contract
      end
      failures
    end

    private

    def contract_honoured?(env_var, var_value, var_contract)
      ValidateEnvVariable.new.call(env_var, var_value, var_contract)
    end

    def as_array(value)
      value.is_a?(Array) ? value : [value] # Wraps nil (in contrast to Array.wrap)
    end

    def environment_specific?(var_contract)
      var_contract.respond_to?(:has_key?)
    end

  end
end