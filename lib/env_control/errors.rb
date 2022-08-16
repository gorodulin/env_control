
module EnvControl

  class Error < StandardError
    def initialize(msg = nil, context:)
      super(details(context))
    end
  end

  class BreachOfContractError < Error
    MSG = "Some ENV variables breach the contract: %s"

    def details(context)
      MSG % [context[:report].inspect]
    end
  end

  class EmptyEnvironmentNameError < Error
    MSG = "contract of %s variable requires environment name to be set"

    def details(context)
      MSG % [context[:var_name]]
    end
  end

  class ContractFormatError < Error
    MSG = "validator %s (%s) for %s variable (%s environment)"

    def details(context)
      MSG % [
        context.fetch(:var_contract).inspect,
        context.fetch(:var_contract).class.inspect,
        context.fetch(:var_name),
        context.fetch(:environment, "any")
      ]
    end
  end

  class MissingEnvironmentError < ContractFormatError
    MSG = "Contract for %s variable is missing %s environment"

    def details(context)
      MSG % [
        context.fetch(:var_name),
        context.fetch(:environment),
      ]
    end
  end

  class NonStringEnvironmentNameError < ContractFormatError
    MSG = "Invalid environment name in %s variable contract"

    def details(context)
      MSG % [
        context.fetch(:var_name),
      ]
    end
  end

  class WrongValidatorTypeError < ContractFormatError
    MSG = "contract %s contains a wrong validator (%s) for %s variable (%s environment)"

    def details(context)
      MSG % [
        context.fetch(:var_contract).inspect,
        context.fetch(:var_validator).class.inspect,
        context.fetch(:var_name),
        context.fetch(:environment, "any")
      ]
    end
  end

  class EmptyContractError < ContractFormatError
    MSG = "contract %s (%s) for %s variable (%s environment)"
  end

  class NonSymbolicKeyError < Error
    MSG = "Not a Symbol key %s (%s) for %s contract"

    def details(context)
      MSG % [
        context[:key].inspect,
        context[:key].class.inspect,
        context[:env_var],
      ]
    end
  end

end