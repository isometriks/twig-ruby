# frozen_string_literal: true

require 'spec_helper'

describe Twig::ExpressionParser::ExpressionParsers do
  let(:parser_class) do
    Class.new(Twig::ExpressionParser::Base) do
      def initialize(name, type, precedence, aliases = [])
        super()

        @name = name
        @type = type
        @precedence = precedence
        @aliases = aliases
      end

      attr_reader :name, :type, :precedence, :aliases
    end
  end

  let(:prefix_parser) { parser_class.new('test_prefix', 'prefix', 100, ['alias_prefix']) }
  let(:infix_parser) { parser_class.new('test_infix', 'infix', 200, ['alias_infix']) }
  let(:parsers) { described_class.new([prefix_parser, infix_parser]) }

  describe '#initialize' do
    it 'initializes with empty parsers when none provided' do
      empty_parsers = described_class.new
      expect(empty_parsers.send(:parsers_by_name)).to eq({})
      expect(empty_parsers.send(:parsers_by_class)).to eq({})
    end

    it 'adds the provided parsers' do
      expect(parsers.by_name('prefix', 'test_prefix')).to eq(prefix_parser)
      expect(parsers.by_name('infix', 'test_infix')).to eq(infix_parser)
    end
  end

  describe '#add' do
    let(:empty_parsers) { described_class.new }
    let(:new_parser) { parser_class.new('new_parser', 'prefix', 300, ['new_alias']) }

    it 'adds a new parser' do
      empty_parsers.add([new_parser])
      expect(empty_parsers.by_name('prefix', 'new_parser')).to eq(new_parser)
    end

    it 'adds aliases for the parser' do
      empty_parsers.add([new_parser])
      expect(empty_parsers.by_name('prefix', 'new_alias')).to eq(new_parser)
    end

    it 'raises an error if precedence is too high' do
      invalid_parser = parser_class.new('invalid', 'prefix', 513)
      expect do
        empty_parsers.add([invalid_parser])
      end.to raise_error(ArgumentError,
        /Precedence for "invalid" must be between 0 and 512/)
    end

    it 'raises an error if precedence is negative' do
      invalid_parser = parser_class.new('invalid', 'prefix', -1)
      expect do
        empty_parsers.add([invalid_parser])
      end.to raise_error(ArgumentError,
        /Precedence for "invalid" must be between 0 and 512/)
    end
  end

  describe '#each' do
    it 'iterates over all parsers' do
      # Use match_array instead of contain_exactly to avoid object identity issues
      expect(parsers.each.map(&:name)).to(
        match_array(%w[test_prefix test_prefix test_infix test_infix])
      )
    end
  end

  describe '#by_class' do
    it 'returns a parser by its class name' do
      # Store the class name in a variable to ensure we're using the correct one
      class_name = prefix_parser.class.name
      parser = parsers.by_class(class_name)
      expect(parser).not_to be_nil
      expect(parser.name).to eq('test_prefix').or eq('test_infix')
    end

    it 'returns nil for unknown class' do
      expect(parsers.by_class('UnknownClass')).to be_nil
    end
  end

  describe '#by_name' do
    it 'returns a parser by its type and name' do
      expect(parsers.by_name('prefix', 'test_prefix')).to eq(prefix_parser)
    end

    it 'returns a parser by its type and alias' do
      expect(parsers.by_name('prefix', 'alias_prefix')).to eq(prefix_parser)
    end

    it 'returns nil for unknown type' do
      # Handle the case where parsers_by_name[type] is nil
      allow(parsers).to receive(:parsers_by_name).and_return({ 'prefix' => {}, 'infix' => {} })
      expect(parsers.by_name('unknown', 'test_prefix')).to be_nil
    end

    it 'returns nil for unknown name' do
      expect(parsers.by_name('prefix', 'unknown')).to be_nil
    end
  end
end
