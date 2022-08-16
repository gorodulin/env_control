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
    let(:so_validate_contract_format) { instance_double(EnvControl::ValidateContractFormat) }
    let(:so_validate_contract) { instance_double(EnvControl::ValidateContract) }
    let(:configuration) { instance_double(EnvControl::Configuration, contract: contract, environment_name: environment_name, on_validation_error: on_validation_error) }
    let(:contract) { { "MY_VAR" => "true" } }
    let(:env) { { "MY_VAR" => "true" } }
    let(:environment_name) { nil }
    let(:on_validation_error) { proc { _1 } }

    before do
      allow(EnvControl::Configuration).to receive(:instance).and_return(configuration)
      allow(EnvControl::ValidateContractFormat).to receive(:new).and_return(so_validate_contract_format)
      allow(EnvControl::ValidateContract).to receive(:new).and_return(so_validate_contract)
    end

    it "validates contract format and environment variables" do
      expect(so_validate_contract_format)
        .to receive(:call)
        .with(contract: subject.configuration.contract, environment_name: environment_name)
      expect(so_validate_contract)
        .to receive(:call)
        .with(env: env, contract: contract, environment_name: environment_name)
        .and_return({MY_VAR: ["true"]})
      subject.validate(env)
    end
  end

end
