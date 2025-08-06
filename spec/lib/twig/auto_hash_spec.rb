# frozen_string_literal: true

require 'spec_helper'

describe Twig::AutoHash do
  describe '#add' do
    it 'adds values with auto-incrementing integer keys' do
      auto_hash = described_class.new

      auto_hash.add('value1')
      expect(auto_hash[0]).to eq('value1')

      auto_hash.add('value2')
      expect(auto_hash[1]).to eq('value2')

      auto_hash.add('value3', 'value4')
      expect(auto_hash[2]).to eq('value3')
      expect(auto_hash[3]).to eq('value4')
    end

    it 'returns self for method chaining' do
      auto_hash = described_class.new
      result = auto_hash.add('value1')

      expect(result).to be(auto_hash)
    end

    it 'continues from the highest integer key' do
      auto_hash = described_class.new
      auto_hash[5] = 'existing'

      auto_hash.add('new')
      expect(auto_hash[6]).to eq('new')
    end

    it 'ignores non-integer keys when determining the next key' do
      auto_hash = described_class.new
      auto_hash['string_key'] = 'string value'
      auto_hash[:symbol_key] = 'symbol value'

      auto_hash.add('new')
      expect(auto_hash[0]).to eq('new')
    end
  end

  describe '#<<' do
    it 'is an alias for #add' do
      auto_hash = described_class.new

      auto_hash << 'value1'
      expect(auto_hash[0]).to eq('value1')

      auto_hash << 'value2' << 'value3'
      expect(auto_hash[1]).to eq('value2')
      expect(auto_hash[2]).to eq('value3')
    end
  end

  describe '#next_key' do
    it 'is a private method' do
      auto_hash = described_class.new
      expect { auto_hash.next_key }.to raise_error(NoMethodError)
    end
  end
end
