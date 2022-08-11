# frozen_string_literal: true

require_relative "env_contract_example"
require_relative "rollbar_config"

# We need a separate contract to run staging apps safely in "production" environment.
# To make it possible we get environment name from combination of two variables
# instead of just reading RAILS_ENV value.
environment_name = env >= {"RAILS_ENV" => "production", "STAGING" => "true"} ? "staging" : env.fetch("RAILS_ENV")

report_to_rollbar_and_fail = lambda do |violations|
  Rollbar.error(violations.inspect)
  fail violations.inspect
end

EnvControl.validate(env, environment_name: environment_name, on_validation_error: report_to_rollbar_and_fail)
