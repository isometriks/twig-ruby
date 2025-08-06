# frozen_string_literal: true

require 'spec_helper'

describe Twig::TwigFunction do
  let(:name) { 'test_function' }
  let(:callable) { proc { |arg| "Result: #{arg}" } }

  describe '#initialize' do
    it 'sets default function-specific options' do
      function = described_class.new(name)

      expect(function.safe(nil)).to eq([])
      expect(function.node_class).to eq(Twig::Node::Expression::Function)
      expect(function.parser_callable).to be_nil
    end

    it 'allows overriding default options' do
      options = {
        is_safe: ['html'],
        node_class: String,
        parser_callable: proc { |_parser, _token| 'parsed' },
      }

      function = described_class.new(name, callable, options)

      expect(function.safe(nil)).to eq(['html'])
      expect(function.node_class).to eq(String)
      expect(function.parser_callable).to be_a(Proc)
    end
  end

  describe '#safe' do
    context 'when is_safe option is set' do
      it 'returns the is_safe value' do
        function = described_class.new(name, callable, is_safe: ['html'])

        expect(function.safe(nil)).to eq(['html'])
      end
    end

    context 'when is_safe_callback option is set' do
      it 'calls the callback with the function arguments' do
        callback = proc { |args| args ? ['html'] : [] }
        function = described_class.new(name, callable, is_safe_callback: callback)

        function_args = double('function_args')
        expect(function.safe(function_args)).to eq(['html'])
      end
    end

    context 'when neither is_safe nor is_safe_callback is set' do
      it 'returns an empty array' do
        function = described_class.new(name)

        expect(function.safe(nil)).to eq([])
      end
    end
  end

  describe '#type' do
    it 'returns :function' do
      function = described_class.new(name)

      expect(function.type).to eq(:function)
    end
  end

  describe '#parser_callable' do
    it 'returns the parser_callable option' do
      parser_callable = proc { |_parser, _token| 'parsed' }
      function1 = described_class.new(name)
      function2 = described_class.new(name, callable, parser_callable: parser_callable)

      expect(function1.parser_callable).to be_nil
      expect(function2.parser_callable).to eq(parser_callable)
    end
  end

  describe '#node_class' do
    it 'returns the node_class option' do
      function1 = described_class.new(name)
      function2 = described_class.new(name, callable, node_class: String)

      expect(function1.node_class).to eq(Twig::Node::Expression::Function)
      expect(function2.node_class).to eq(String)
    end
  end
end
