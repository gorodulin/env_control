# frozen_string_literal: true

require 'spec_helper.rb'

RSpec.describe EnvControl::Configuration do
  subject { described_class.instance }

  before(:each) { Singleton.__init__(described_class) }

  it "follows singleton pattern" do
    expect(described_class.included_modules).to include(Singleton)
    expect(described_class).to respond_to(:instance)
  end

  describe "'contract' setting" do
    it "empty Hash by default" do
      expect(subject.contract).to eq({})
    end

    it "can be set and read" do
      subject.contract = { "A" => "B" }
      expect(subject.contract).to eq({ "A" => "B" })
    end

    it "must be a Hash (or similar object)" do
      expect { subject.contract = nil }
        .to raise_error ArgumentError, /must respond to #each_pair/
    end
  end

  describe "'environment_name' setting" do
    it "nil by default" do
      expect(subject.environment_name).to be_nil
    end

    it "can be set and read" do
      subject.environment_name = "production"
      expect(subject.environment_name).to eq("production")
    end

    context "when being set" do
      it "turns non-nil values into String (including callables)" do
        {
          proc { true } => "true",
          false => "false",
          11 => "11",
          { a: :a } => "{:a=>:a}",
        }.each do |value, expected_value|
          subject.environment_name = value
          expect(subject.environment_name).to eq(expected_value)
        end
      end

      it "allows nils" do
        {
          proc { nil } => nil,
          nil => nil,
        }.each do |value, expected_value|
          subject.environment_name = value
          expect(subject.environment_name).to eq(expected_value)
        end
      end

      it "raises error if empty String ''" do
        expect { subject.environment_name = "" }
          .to raise_error ArgumentError, /Non-empty string or nil expected/
      end
    end
  end
end
