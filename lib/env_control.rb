# frozen_string_literal: true

require "forwardable"

module EnvControl

  autoload(:BreachOfContractError,              "env_control/errors.rb")
  autoload(:Configuration,                      "env_control/configuration.rb")
  autoload(:EnvironmentNameNotConfiguredError,  "env_control/errors.rb")
  autoload(:GetEnvironmentSpecificContract,     "env_control/get_environment_specific_contract.rb")
  autoload(:NonStringEnvironmentNameError,      "env_control/errors.rb")
  autoload(:NonSymbolicKeyError,                "env_control/errors.rb")
  autoload(:ValidateEnvContract,                "env_control/validate_env_contract.rb")
  autoload(:ValidateEnvVariable,                "env_control/validate_env_variable.rb")
  autoload(:ValidateEnvVariables,               "env_control/validate_env_variables.rb")
  autoload(:Validators,                         "env_control/validators.rb")
  autoload(:VERSION,                            "env_control/version.rb")
  autoload(:WrongValueError,                    "env_control/errors.rb")

  def self.configuration
    Configuration.instance
  end

  def self.configure(&block)
    yield Configuration.instance
  end

  def self.validate(
      env,
      contract: configuration.contract,
      environment_name: configuration.environment_name,
      on_validation_error: configuration.on_validation_error
    )
    ValidateEnvContract.new.call(contract: contract)
    report = ValidateEnvVariables.new.call(
      env: env,
      contract: contract,
      environment_name: environment_name
    )
    return {} if report.empty?
    on_validation_error ? on_validation_error.call(report) : report
  end

end
