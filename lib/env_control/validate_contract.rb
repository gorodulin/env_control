# frozen_string_literal: true

module EnvControl
  class ValidateContract
    include Helpers

    def call(contract:, env:, environment_name:)
      # validate_contract_format!(contract, environment_name)
      failures = {}
      contract.each do |env_var, var_contracts|
        unless environment_specific?(var_contracts)
          var_contract = as_array(var_contracts)
        else
          var_contract = as_array(var_contracts[environment_name] || var_contracts["default"])
        end
        next unless var_contract # No environment-specific contract found
        var_value = env.fetch(env_var.to_s, nil)
        next if contract_honoured?(env_var, var_value, var_contract)

        failures[env_var] = var_contract
      end
      failures
    end

    private

    def validate_contract_format!(contract, environment_name)
      ValidateContractFormat.new.call(
        contract: contract,
        environment_name: environment_name
      )
    end

    def contract_honoured?(env_var, var_value, var_contract)
      ValidateEnvVariable.new.call(env_var, var_value, var_contract)
    end

  end
end