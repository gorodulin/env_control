# frozen_string_literal: true

require 'spec_helper.rb'

RSpec.describe EnvControl::ValidateEnvVariables do

  subject { described_class.new.call(contract: contract, env: env, environment_name: environment_name) }

  let(:valid_contract) do
    {
      ON_OFF: ["on", "off"],
      DATABASE_URL: {
        "production" => :string,
        "default" => [->(url) { !url.include?("prod") }, :not_set],
      },
      BOOL_VAR: {
        "production" => "true",
        "staging" => "false",
        "default" => :not_set,
      },
    }
  end

  let(:contract) { valid_contract }
  let(:environment_name) { "production" }

  context "when all contracts are amply honoured" do
    let(:env) { { "ON_OFF" => "on", "DATABASE_URL" => "url", "BOOL_VAR" => "true" } }
    it "returns empty Hash" do
      expect(subject).to eq({})
    end
  end

  context "when some contracts are broken" do
    let(:env) { { "ON_OFF" => "foo", "DATABASE_URL" => "db_prod" } }
    it "returns Hash containing variables with contract breaches" do
      expect(subject).to eq({ ON_OFF: ["on", "off"], BOOL_VAR: ["true"]})
    end
  end

  context "when environment is not set" do
    let(:environment_name) { nil }
    let(:env) { { "DATABASE_URL" => "url" } }
    context "when environment-specific contract exists" do
      it "raises EnvironmentNameNotConfiguredError error" do
        expect { subject }.to raise_error(EnvControl::EnvironmentNameNotConfiguredError, /DATABASE_URL/)
      end
    end
  end

  context "when environment is set" do
    let(:env) { { "ON_OFF" => "on", "BOOL_VAR" => "invalid value" } }

    context "when environment-specific contract exists" do
      let(:environment_name) { "staging" }
      it "picks the right contract" do
        expect(subject).to eq({ BOOL_VAR: ["false"] })
      end
    end

    context "when environment-specific contract does not exist" do
      let(:environment_name) { "test" }

      context "when there is 'default' contract" do
        it "picks the default contract" do
          expect(subject).to eq({ BOOL_VAR: [:not_set] })
        end
      end

      context "when there is no 'default' contract" do
        let(:contract) { valid_contract.merge(BOOL_VAR: { "staging" => "false" }) }
        it "does nothing as if there is no contract" do
          expect(subject).to eq({})
        end
      end
    end
  end
end
