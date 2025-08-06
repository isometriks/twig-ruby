# frozen_string_literal: true

require 'spec_helper'

describe Twig::Callable do
  let(:name) { 'test_callable' }
  let(:proc_callable) { proc { |arg| "Result: #{arg}" } }

  describe '#initialize' do
    it 'sets name and dynamic_name to the provided name' do
      callable = described_class.new(name)

      expect(callable.name).to eq(name)
      expect(callable.dynamic_name).to eq(name)
    end

    it 'initializes arguments as an empty array' do
      callable = described_class.new(name)

      expect(callable.arguments).to eq([])
    end

    it 'sets the callable to the provided callable' do
      callable = described_class.new(name, proc_callable)

      expect(callable.callable).to eq(proc_callable)
    end

    it 'sets default options' do
      callable = described_class.new(name)

      expect(callable.needs_environment?).to be(false)
      expect(callable.needs_context?).to be(false)
      expect(callable.needs_charset?).to be(false)
    end

    it 'allows overriding default options' do
      options = {
        needs_environment: true,
        needs_context: true,
        needs_charset: true,
        is_variadic: true,
      }

      callable = described_class.new(name, proc_callable, options)

      expect(callable.needs_environment?).to be(true)
      expect(callable.needs_context?).to be(true)
      expect(callable.needs_charset?).to be(true)
    end
  end

  describe '#type' do
    it 'raises NotImplementedError' do
      callable = described_class.new(name)

      expect { callable.type }.to raise_error(NotImplementedError)
    end
  end

  describe '#needs_charset?' do
    it 'returns the value of the needs_charset option' do
      callable = described_class.new(name, nil, needs_charset: true)

      expect(callable.needs_charset?).to be(true)
    end
  end

  describe '#needs_environment?' do
    it 'returns the value of the needs_environment option' do
      callable = described_class.new(name, nil, needs_environment: true)

      expect(callable.needs_environment?).to be(true)
    end
  end

  describe '#needs_context?' do
    it 'returns the value of the needs_context option' do
      callable = described_class.new(name, nil, needs_context: true)

      expect(callable.needs_context?).to be(true)
    end
  end

  describe '#with_dynamic_arguments' do
    it 'returns a clone with updated name, dynamic_name, and arguments' do
      callable = described_class.new(name, proc_callable)
      new_name = 'new_name'
      new_dynamic_name = 'new_dynamic_name'
      new_arguments = [1, 2, 3]

      new_callable = callable.with_dynamic_arguments(new_name, new_dynamic_name, new_arguments)

      expect(new_callable).not_to be(callable)
      expect(new_callable.name).to eq(new_name)
      expect(new_callable.dynamic_name).to eq(new_dynamic_name)
      expect(new_callable.arguments).to eq(new_arguments)
      expect(new_callable.callable).to eq(proc_callable)
    end
  end
end
