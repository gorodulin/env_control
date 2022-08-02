# frozen_string_literal: true

require 'spec_helper.rb'

RSpec.describe EnvControl::GetEnvironmentSpecificContract do
  subject { described_class.new.call(env_var: env_var, contracts: contracts, environment_name: environment_name) }

  let(:env_var) { :MY_VAR }

  context "when environment has a contract" do
    let(:environment_name) { "production" }
    let(:contracts) do
      {
        "production" => nil,
        "default" => :string,
      }
    end

    it "picks corresponding contract even if the value is nil" do
      expect(subject).to eq([nil])
    end
  end

  context "when environment has no contract" do
    let(:environment_name) { "development" }

    context "when there is a fallback ('default') contract" do
      let(:contracts) { { "default" => :default } }
      it "returns default value" do
        expect(subject).to eq([:default])
      end
    end

    context "when there is no fallback ('default') contract" do
      let(:contracts) { { "production" => nil } }
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
  end

end
