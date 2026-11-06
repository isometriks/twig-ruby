# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Error::Syntax do
  describe '#add_suggestions' do
    let(:error) { described_class.new('Unknown "uper" filter.', 1, Twig::Source.new('', 'index')) }

    it 'suggests the items close to the name or that contain it, closest first' do
      error.add_suggestions('uper', %w[lower upper super paper uper_case])

      expect(error.message).
        to eq('Unknown "uper" filter. Did you mean "upper", "super", "uper_case" in "index" at line 1?')
    end

    it 'leaves the message alone without a suggestion' do
      error.add_suggestions('uper', %w[lower trim])

      expect(error.message).to eq('Unknown "uper" filter in "index" at line 1.')
    end

    it 'takes symbols' do
      error.add_suggestions('fo', %i[for if])

      expect(error.message).to eq('Unknown "uper" filter. Did you mean "for" in "index" at line 1?')
    end
  end

  describe '.levenshtein' do
    it 'counts the edits between the bytes of two strings, as PHP does' do
      expect(described_class.levenshtein('kitten', 'sitting')).to eq(3)
      expect(described_class.levenshtein('', 'abc')).to eq(3)
      expect(described_class.levenshtein('abc', 'abc')).to eq(0)
      expect(described_class.levenshtein('é', 'e')).to eq(2)
    end
  end
end
