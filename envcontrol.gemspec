# frozen_string_literal: true

require_relative "lib/env_control/version"

Gem::Specification.new do |spec|
  spec.name          = "env_control"
  spec.version       = EnvControl::VERSION
  spec.authors       = ["Vladimir Gorodulin"]
  spec.email         = ["ru.hostmaster@gmail.com"]
  spec.description   = %q{Ruby approach in creating contracts for ENV variables}
  spec.description   = %q{Contract-based prevention from running your app with invalid ENV variables}
  spec.summary       = <<-EOS
  Prevent your app from running with invalid ENV variables.
  Define a contract that lists all the required/optional environment
  variables along with their peculiar protective constraints
  specific to your application.
  EOS
  spec.homepage      = "https://github.com/gorodulin/env_control"
  spec.license       = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata = {
    "changelog_uri"     => "https://github.com/gorodulin/env_control/CHANGELOG.md",
    "homepage_uri"      => spec.homepage,
    "source_code_uri"   => "https://github.com/gorodulin/env_control",
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { _1.match(%r{^(bin/|spec/|config/|\.)}) }
  end

  spec.require_paths = ["lib"]
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
end
