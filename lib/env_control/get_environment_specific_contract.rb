# frozen_string_literal: true

module EnvControl
  class GetEnvironmentSpecificContract

    def call(env_var:, contracts:, environment_name:)
      unless environment_name
        raise EnvironmentNameNotConfiguredError.new(context: { env_var: env_var })
      end

      @contracts = contracts

      contract_for(environment_name) || contract_for("default")
    end

    private

    def contract_for(environment_name)
      return nil unless @contracts.has_key?(environment_name)

      contract = @contracts[environment_name]
      contract.is_a?(Array) ? contract : [contract]
    end

  end
end
