# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::FileExtensionEscapingStrategy do
  describe '#guess' do
    it 'guesses javascript templates' do
      expect(described_class.guess('foo.js.twig')).to eq(:js)
      expect(described_class.guess('foo.json.twig')).to eq(:js)
    end

    it 'does not escape for plain text' do
      expect(described_class.guess('plain.txt.twig')).to eq(false)
    end

    it 'guesses css templates' do
      expect(described_class.guess('foo.css.twig')).to eq(:css)
    end

    it 'returns html by default' do
      expect(described_class.guess('foo.asdf.twig')).to eq(:html)
    end
  end
end
