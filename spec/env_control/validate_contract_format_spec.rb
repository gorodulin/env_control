# frozen_string_literal: true

require 'spec_helper.rb'

RSpec.describe EnvControl::ValidateContractFormat do

  subject { described_class.new.call(contract: contract, environment_name: environment_name) }

  let(:valid_contract) do
    {
      ARRAY_ONE:    ['on', 'off', nil],
      ARRAY_TWO:    [:bool, -> { true }],
      SWITCH:       ['on', 'off'],
      W_VALIDATOR:  :integer,
      EMPTY_VAR:    '',
      NOT_SET:      nil,
    }
  end

  let(:environment_specific_part) do
    {
      ENV_SPECIFIC: {
        "production" => :aws_login,
        "staging" => [:bool, -> { true }, ''],
        "review" => ['dummy_value', :integer, :nil],
        "default" => :not_set,
      }
    }
  end

  let(:contract) { valid_contract }

  let(:environment_name) { "production" }

  context "when contract format is VALID" do
    it "does not raise error" do
      expect { subject }.not_to raise_error
    end

    context "when there are no environment-specific requirements" do
      context "when environment is unknown" do
        let(:environment) { nil }
        it 'does not require environment to be set' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context "when there are environment-specific requirements" do
      let(:contract) { valid_contract.merge(environment_specific_part) }

      context "when environment is known" do
        it "does not raise error" do
          expect { subject }.not_to raise_error
        end
      end

      context "when environment is unknown" do
        let(:environment_name) { nil }
        it 'raises EnvironmentNameNotConfiguredError error' do
          expect { subject }.to raise_error(EnvControl::EmptyEnvironmentNameError, /contract of ENV_SPECIFIC/)
        end
      end
    end
  end

  context "when variable contract format is INVALID" do
    context "when variable name is not a Symbol" do
      let(:contract) { valid_contract.merge("NOT_A_SYMBOL" => "value") }

      it "raises NonSymbolicKeyError error" do
        expect { subject }.to raise_error(EnvControl::NonSymbolicKeyError)
      end
    end

    context "when Array" do
      context "when empty Array" do
        let(:contract) { valid_contract.merge(MY_ENV_VAR: []) }

        it "raises EmptyContractError error" do
          expect { subject }.to raise_error(EnvControl::EmptyContractError, /\[\].*Array/)
        end
      end

      context "when contains an invalid validator" do
        let(:contract) { valid_contract.merge(MY_ENV_VAR: [:string, 222, 1..10]) }

        it "raises WrongValidatorTypeError error" do
          expect { subject }.to raise_error(EnvControl::WrongValidatorTypeError, /contains a wrong validator \(Integer\)/)
        end
      end

    end

    context "when Integer" do
      let(:contract) { valid_contract.merge(MY_ENV_VAR: 222) }

      it "raises WrongValidatorTypeError error" do
        expect { subject }.to raise_error(EnvControl::WrongValidatorTypeError, /222 contains a wrong validator \(Integer\)/)
      end
    end

    context "when Range" do
      let(:contract) { valid_contract.merge(MY_ENV_VAR: 1..100) }

      it "raises WrongValidatorTypeError error" do
        expect { subject }.to raise_error(EnvControl::WrongValidatorTypeError, /100 contains a wrong validator \(Range\)/)
      end
    end

    context "when there are environment-specific requirements" do
      let(:contract) { valid_contract.merge(environment_specific_part) }

      context "when contract contains a non-String key" do
        let(:environment_specific_part) { { ENV_SPECIFIC: { a_symbol_key: nil } } }
        it "raises NonStringEnvironmentNameError error" do
          expect { subject }.to raise_error(EnvControl::NonStringEnvironmentNameError, /Invalid environment name in ENV_SPECIFIC variable contract/)
        end
      end

      context "when contract for current environment is missing" do
        let(:environment_name) { "an_environment" }

        context "when \"default\" section present" do
          let(:environment_specific_part) { { ENV_SPECIFIC: { "default" => :string } } }
          it "does not raise error" do
            expect { subject }.not_to raise_error
          end
        end

        context "when there is no \"default\" section" do
          let(:environment_specific_part) { { ENV_SPECIFIC: { "production" => :string } } }
          it "raises MissingEnvironmentError error" do
            expect { subject }.to raise_error(EnvControl::MissingEnvironmentError, /Contract for ENV_SPECIFIC var/)
          end
        end
      end

      context "when empty" do
        let(:contract) { valid_contract.merge(MY_ENV_VAR: {}) }

        it "raises WrongValueError error" do
          expect { subject }.to raise_error(EnvControl::EmptyContractError, /\{\}.*Hash/)
        end
      end
    end
  end
end


# RSpec.shared_examples 'does not require environment to be set' do
#   context "when environment name is unknown" do
#     let(:environment_name) { "development" }

#     it "does not raise error" do
#       expect { subject }.not_to raise_error
#     end
#   end
# end
# it_behaves_like 'does not require environment to be set'
