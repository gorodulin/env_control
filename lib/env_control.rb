# frozen_string_literal: true

require "forwardable"

module EnvControl

  autoload(:BreachOfContractError,              "env_control/errors.rb")
  autoload(:Configuration,                      "env_control/configuration.rb")
  autoload(:EmptyEnvironmentNameError,          "env_control/errors.rb")
  autoload(:Helpers,                            "env_control/helpers.rb")
  autoload(:MissingEnvironmentError,            "env_control/errors.rb")
  autoload(:NonStringEnvironmentNameError,      "env_control/errors.rb")
  autoload(:NonSymbolicKeyError,                "env_control/errors.rb")
  autoload(:VERSION,                            "env_control/version.rb")
  autoload(:ValidateContract,                   "env_control/validate_contract.rb")
  autoload(:ValidateContractFormat,             "env_control/validate_contract_format.rb")
  autoload(:ValidateVariableContract,           "env_control/validate_variable_contract.rb")
  autoload(:Validators,                         "env_control/validators.rb")
  autoload(:WrongContractError,                 "env_control/errors.rb")
  autoload(:WrongValidatorTypeError,            "env_control/errors.rb")

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
    report = ValidateContract.new.call(
      env: env,
      contract: contract,
      environment_name: environment_name
    )
    return {} if report.empty?
    on_validation_error ? on_validation_error.call(report) : report
  end

end
