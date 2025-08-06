# frozen_string_literal: true

require 'spec_helper'

describe Twig::Cache::Nil do
  let(:cache) { described_class.new }

  describe '#generate_key' do
    it 'returns an empty string regardless of input' do
      expect(cache.generate_key('template_name', 'ClassName')).to eq('')
      expect(cache.generate_key(nil, nil)).to eq('')
    end
  end

  describe '#timestamp' do
    it 'returns 0 regardless of input' do
      expect(cache.timestamp('any_key')).to eq(0)
      expect(cache.timestamp(nil)).to eq(0)
    end
  end

  describe '#write' do
    it 'does nothing and returns nil' do
      expect(cache.write('key', 'content')).to be_nil
    end
  end

  describe '#load' do
    it 'does nothing and returns nil' do
      expect(cache.load('key')).to be_nil
    end
  end

  describe '#remove' do
    it 'does nothing and returns nil' do
      expect(cache.remove('key')).to be_nil
    end
  end

  it 'inherits from Twig::Cache::Base' do
    expect(described_class.superclass).to eq(Twig::Cache::Base)
  end
end
