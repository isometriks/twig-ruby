# frozen_string_literal: true

require 'spec_helper'

describe Twig::Token do
  let(:type) { :name }
  let(:value) { 'variable_name' }
  let(:lineno) { 42 }
  let(:token) { described_class.new(type, value, lineno) }

  describe '#initialize' do
    it 'sets the type, value, and lineno' do
      expect(token.type).to eq(type)
      expect(token.value).to eq(value)
      expect(token.lineno).to eq(lineno)
    end
  end

  describe '#test' do
    context 'when only type is provided' do
      it 'returns true if the token type matches' do
        expect(token.test(:name)).to be(true)
      end

      it 'returns false if the token type does not match' do
        expect(token.test(:number)).to be(false)
      end
    end

    context 'when type and values are provided' do
      it 'returns true if the token type and value match' do
        expect(token.test(:name, 'variable_name')).to be(true)
      end

      it 'returns true if the token type matches and value is in the array' do
        expect(token.test(:name, %w[variable_name other_name])).to be(true)
      end

      it 'returns false if the token type matches but value does not' do
        expect(token.test(:name, 'other_name')).to be(false)
      end

      it 'returns false if the token type matches but value is not in the array' do
        expect(token.test(:name, %w[other_name another_name])).to be(false)
      end
    end

    context 'when only values are provided (not a Symbol)' do
      it 'assumes NAME_TYPE and returns true if the value matches' do
        expect(token.test('variable_name')).to be(true)
      end

      it 'assumes NAME_TYPE and returns true if the value is in the array' do
        expect(token.test(%w[variable_name other_name])).to be(true)
      end

      it 'assumes NAME_TYPE and returns false if the value does not match' do
        expect(token.test('other_name')).to be(false)
      end
    end
  end

  describe '#debug' do
    it 'returns an array with type and value' do
      expect(token.debug).to eq([type, value])
    end
  end

  describe '#to_english' do
    it 'returns the English description of the token type' do
      expect(token.to_english).to eq('name')
    end
  end

  describe '.type_to_english' do
    it 'returns the English description for known token types' do
      expect(described_class.type_to_english(:eof)).to eq('end of template')
      expect(described_class.type_to_english(:text)).to eq('text')
      expect(described_class.type_to_english(:block_start)).to eq('begin of statement block')
      expect(described_class.type_to_english(:name)).to eq('name')
    end

    it 'raises ArgumentError for unknown token types' do
      expect { described_class.type_to_english(:unknown_type) }.to raise_error(
        ArgumentError, 'Token of type "unknown_type" does not exist.'
      )
    end
  end

  describe 'token type constants' do
    it 'defines token type constants' do
      expect(described_class::EOF_TYPE).to eq(:eof)
      expect(described_class::TEXT_TYPE).to eq(:text)
      expect(described_class::BLOCK_START_TYPE).to eq(:block_start)
      expect(described_class::VAR_START_TYPE).to eq(:var_start)
      expect(described_class::BLOCK_END_TYPE).to eq(:block_end)
      expect(described_class::VAR_END_TYPE).to eq(:var_end)
      expect(described_class::NAME_TYPE).to eq(:name)
      expect(described_class::SYMBOL_TYPE).to eq(:symbol)
      expect(described_class::CLASS_VAR_TYPE).to eq(:class_var)
      expect(described_class::NUMBER_TYPE).to eq(:number)
      expect(described_class::STRING_TYPE).to eq(:string)
      expect(described_class::OPERATOR_TYPE).to eq(:operator)
      expect(described_class::PUNCTUATION_TYPE).to eq(:punctuation)
      expect(described_class::INTERPOLATION_START_TYPE).to eq(:interpolation_start)
      expect(described_class::INTERPOLATION_END_TYPE).to eq(:interpolation_end)
    end
  end
end
