# frozen_string_literal: true

require 'spec_helper'

describe Twig::TwigTest do
  let(:name) { 'test_test' }
  let(:callable) { proc { |value| value.is_a?(String) } }

  describe '#initialize' do
    it 'sets default test-specific options' do
      test = described_class.new(name)

      expect(test.node_class).to eq(Twig::Node::Expression::Test::Base)
      expect(test.one_mandatory_argument?).to be(false)
    end

    it 'allows overriding default options' do
      options = {
        node_class: String,
        one_mandatory_argument: true,
      }

      test = described_class.new(name, callable, options)

      expect(test.node_class).to eq(String)
      expect(test.one_mandatory_argument?).to be(true)
    end
  end

  describe '#type' do
    it 'returns :test' do
      test = described_class.new(name)

      expect(test.type).to eq(:test)
    end
  end

  describe '#node_class' do
    it 'returns the node_class option' do
      test1 = described_class.new(name)
      test2 = described_class.new(name, callable, node_class: String)

      expect(test1.node_class).to eq(Twig::Node::Expression::Test::Base)
      expect(test2.node_class).to eq(String)
    end
  end

  describe '#one_mandatory_argument?' do
    it 'returns the one_mandatory_argument option' do
      test1 = described_class.new(name)
      test2 = described_class.new(name, callable, one_mandatory_argument: true)

      expect(test1.one_mandatory_argument?).to be(false)
      expect(test2.one_mandatory_argument?).to be(true)
    end
  end

  describe '#needs_context?' do
    it 'always returns false' do
      test = described_class.new(name)

      expect(test.needs_context?).to be(false)
    end

    it 'returns false even if the parent class would return true' do
      test = described_class.new(name, callable, needs_context: true)

      expect(test.needs_context?).to be(false)
    end
  end
end
