# frozen_string_literal: true

require 'spec_helper.rb'

RSpec.describe EnvControl do
  subject { described_class }

  describe "#configuration" do
    it "returns EnvControl::Configuration singleton" do
      expect(subject.configuration).to be_a(EnvControl::Configuration)
    end
  end

  describe "#validate" do
    let(:so_validate_env_contract) { instance_double(EnvControl::ValidateEnvContract) }
    let(:so_validate_env_variables) { instance_double(EnvControl::ValidateEnvVariables) }
    let(:configuration) { instance_double(EnvControl::Configuration, contract: contract, environment_name: environment_name, on_validation_error: on_validation_error) }
    let(:contract) { { "MY_VAR" => "true" } }
    let(:env) { { "MY_VAR" => "true" } }
    let(:environment_name) { nil }
    let(:on_validation_error) { proc { _1 } }

    before do
      allow(EnvControl::Configuration).to receive(:instance).and_return(configuration)
      allow(EnvControl::ValidateEnvContract).to receive(:new).and_return(so_validate_env_contract)
      allow(EnvControl::ValidateEnvVariables).to receive(:new).and_return(so_validate_env_variables)
    end

    it "validates contract format and environment variables" do
      expect(so_validate_env_contract)
        .to receive(:call)
        .with(contract: subject.configuration.contract)
      expect(so_validate_env_variables)
        .to receive(:call)
        .with(env: env, contract: contract, environment_name: environment_name)
        .and_return({MY_VAR: ["true"]})
      subject.validate(env)
    end
  end

end
