# frozen_string_literal: true

require "env_control"

EnvControl.configure do |c|
  c.contract = {}
end

EnvControl.validate!(ENV)
