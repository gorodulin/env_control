# frozen_string_literal: true

require 'spec_helper.rb'

RSpec.describe EnvControl::ValidateVariableContract do

  subject { described_class.new.call(name, value, contract) }

  let(:name) { "DUMMY_VAR" }
  let(:value) { "true" }

  context "when contract contains Hash" do
    let(:contract) { [{}] }
    it { is_expected_to_raise /unknown validator type/ }
  end

  context "when contract contains number" do
    let(:contract) { [11] }
    it { is_expected_to_raise /unknown validator type/ }
  end

  context "when contract is empty" do
    let(:contract) { [] }
    it { is_expected.to eq(false) }
  end

  context "when value satisfies contract" do
    context "when expected String value" do
      let(:value) { "off" }
      let(:contract) { ["on", "off"] }
      it { is_expected.to eq(true) }
    end
    context "when expected Regexp value" do
      let(:value) { "my_prod_database" }
      let(:contract) { [/prod/] }
      it { is_expected.to eq(true) }
    end
  end

  context "when contract is callable" do
    let(:contract) { [->(val) { (val == "expected value") }] }
    context "when value is nil" do
      let(:value) { nil }
      it "always returns false" do
        expect(subject).to eq(false)
      end
    end
    context "when value is String" do
      context "when value satisfies contract" do
        let(:value) { "expected value" }
        it { is_expected.to eq(true) }
      end
      context "when value violates contract" do
        let(:value) { "unexpected value" }
        it { is_expected.to eq(false) }
      end
    end
  end

  def is_expected_to_raise(*args)
    expect { subject }.to raise_exception(*args)
  end
end
