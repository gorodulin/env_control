# frozen_string_literal: true

require 'spec_helper.rb'

RSpec.describe EnvControl::ValidateEnvContract do

  subject { described_class.new.call(contract: contract) }

  let(:valid_contract) do
    {
      ARRAY_ONE:    ['on', 'off', nil],
      ARRAY_TWO:    [:bool, -> { true }],
      ENV_SPECIFIC: {
                      "production" => :aws_login,
                      "staging" => [:bool, -> { true }, ''],
                      "review" => ['dummy_value', :integer, :nil],
                      "default" => :not_set,
                    },
      SWITCH:       ['on', 'off'],
      W_VALIDATOR:  :integer,
      EMPTY_VAR:    '',
      NOT_SET:      nil,
    }
  end

  let(:contract) { valid_contract }

  context "when contract format is valid" do
    it "does not raise error" do
      expect { subject }.not_to raise_error
    end
  end

  context "when key is not a Symbol" do
    let(:contract) { valid_contract.merge("NOT_A_SYMBOL" => "value") }

    it "raises NonSymbolicKeyError error" do
      expect { subject }.to raise_error(EnvControl::NonSymbolicKeyError)
    end
  end

  context "when environment name is not a String" do
    let(:contract) { valid_contract.merge(MY_ENV_VAR: { production: "value" }) }

    it "raises NonStringEnvironmentNameError error" do
      expect { subject }.to raise_error(EnvControl::NonStringEnvironmentNameError)
    end
  end


  context "when value is wrong" do
    context "when Integer" do
      let(:contract) { valid_contract.merge(MY_ENV_VAR: 222) }

      it "raises WrongValueError error" do
        expect { subject }.to raise_error(EnvControl::WrongValueError, /222 \(Integer\)/)
      end
    end

    context "when empty Array" do
      let(:contract) { valid_contract.merge(MY_ENV_VAR: []) }

      it "raises WrongValueError error" do
        expect { subject }.to raise_error(EnvControl::WrongValueError, /\[\].*Array/)
      end
    end

    context "when empty Hash" do
      let(:contract) { valid_contract.merge(MY_ENV_VAR: {}) }

      it "raises WrongValueError error" do
        expect { subject }.to raise_error(EnvControl::WrongValueError, /{}.*Hash/)
      end
    end
  end

end
