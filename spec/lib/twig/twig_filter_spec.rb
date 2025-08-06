# frozen_string_literal: true

require 'spec_helper'

describe Twig::TwigFilter do
  let(:name) { 'test_filter' }
  let(:callable) { proc(&:upcase) }

  describe '#initialize' do
    it 'sets default filter-specific options' do
      filter = described_class.new(name)

      expect(filter.safe(nil)).to eq([])
      expect(filter.preserves_safety).to eq([])
      expect(filter.pre_escape).to be_nil
      expect(filter.node_class).to eq(Twig::Node::Expression::Filter)
    end

    it 'allows overriding default options' do
      options = {
        is_safe: ['html'],
        pre_escape: 'html',
        preserves_safety: ['html'],
        node_class: String,
      }

      filter = described_class.new(name, callable, options)

      expect(filter.safe(nil)).to eq(['html'])
      expect(filter.preserves_safety).to eq(['html'])
      expect(filter.pre_escape).to eq('html')
      expect(filter.node_class).to eq(String)
    end
  end

  describe '#safe' do
    context 'when is_safe option is set' do
      it 'returns the is_safe value' do
        filter = described_class.new(name, callable, is_safe: ['html'])

        expect(filter.safe(nil)).to eq(['html'])
      end
    end

    context 'when is_safe_callback option is set' do
      it 'calls the callback with the filter arguments' do
        callback = proc { |args| args ? ['html'] : [] }
        filter = described_class.new(name, callable, is_safe_callback: callback)

        filter_args = double('filter_args')
        expect(filter.safe(filter_args)).to eq(['html'])
      end
    end

    context 'when neither is_safe nor is_safe_callback is set' do
      it 'returns an empty array' do
        filter = described_class.new(name)

        expect(filter.safe(nil)).to eq([])
      end
    end
  end

  describe '#preserves_safety' do
    it 'returns the preserves_safety option or an empty array by default' do
      filter1 = described_class.new(name)
      filter2 = described_class.new(name, callable, preserves_safety: ['html'])

      expect(filter1.preserves_safety).to eq([])
      expect(filter2.preserves_safety).to eq(['html'])
    end
  end

  describe '#pre_escape' do
    it 'returns the pre_escape option' do
      filter1 = described_class.new(name)
      filter2 = described_class.new(name, callable, pre_escape: 'html')

      expect(filter1.pre_escape).to be_nil
      expect(filter2.pre_escape).to eq('html')
    end
  end

  describe '#type' do
    it 'returns :filter' do
      filter = described_class.new(name)

      expect(filter.type).to eq(:filter)
    end
  end

  describe '#node_class' do
    it 'returns the node_class option' do
      filter1 = described_class.new(name)
      filter2 = described_class.new(name, callable, node_class: String)

      expect(filter1.node_class).to eq(Twig::Node::Expression::Filter)
      expect(filter2.node_class).to eq(String)
    end
  end
end
