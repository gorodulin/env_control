# frozen_string_literal: true

require "singleton"

module EnvControl
  class Configuration
    include Singleton

    attr_accessor :on_validation_error, :validators_allowing_nil
    attr_reader :contract, :environment_name

    DEFAULT_BREACH_HANDLER = lambda do |report|
      fail BreachOfContractError.new(context: { report: report })
    end

    def initialize
      @contract = {}
      @on_validation_error = DEFAULT_BREACH_HANDLER
      @validators_allowing_nil = [:deprecated, :empty, :ignore, :irrelevant, :not_set]
    end

    def contract=(hash)
      unless hash.respond_to?(:each_pair)
        raise ArgumentError, "Argument (#{hash.inspect}) must respond to #each_pair"
      end
      @contract = hash
    end

    def environment_name=(name)
      @environment_name = name.respond_to?(:call) ? name.call&.to_s : name&.to_s

      raise ArgumentError, "Non-empty string or nil expected" if @environment_name == ""
    end

  end
end