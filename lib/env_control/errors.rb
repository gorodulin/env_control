
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

  class EnvironmentNameNotConfiguredError < Error
    MSG = "Can't pick environment-specific contract for %s variable. " +
          "EnvControl.configuration.environment_name is not set."

    def details(context)
      MSG % [context[:env_var]]
    end
  end

  class NonStringEnvironmentNameError < Error
    MSG = "Not a String key %s (%s) for %s contract"

    def details(context)
      MSG % [
        context[:environment_name].inspect,
        context[:environment_name].class.inspect,
        context[:env_var],
      ]
    end
  end

  class WrongValueError < Error
    MSG = "Wrong value: %s (%s) for %s contract (%s environment)"

    def details(context)
      MSG % [
        context[:value].inspect,
        context[:value].class.inspect,
        context[:env_var],
        context[:environment_name] || "any"
      ]
    end
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