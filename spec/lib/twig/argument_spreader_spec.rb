# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::ArgumentSpreader do
  let(:callee) do
    Class.new do
      def none; end
      def positional(a, b, c); end
      def kwarg(a: nil, b: nil, c: nil); end
      def both(a, b, c: nil, d: nil); end
    end.new
  end

  let(:spreader) { described_class.new(method) }
  let(:method) { callee.method(method_name) }

  context 'when method has no arguments' do
    let(:method_name) { :none }

    it 'calls the method' do
      expect(callee).to receive(method_name).with no_args
      spreader.call
    end
  end

  context 'when method has only positional arguments' do
    let(:method_name) { :positional }

    it 'calls the method' do
      expect(callee).to receive(method_name).with(1, 2, 3)
      spreader.call(1, 2, 3)
    end
  end

  context 'when method has a spread of positional arguments' do
    let(:method_name) { :positional }

    it 'calls the method' do
      expect(callee).to receive(method_name).with(1, 2, 3)
      spreader.call(Twig::Spread.new([1, 2, 3]))
    end
  end

  context 'when method has a spread of multiple positional arguments' do
    let(:method_name) { :positional }

    it 'calls the method' do
      expect(callee).to receive(method_name).with(1, 2, 3)
      spreader.call(Twig::Spread.new([1]), Twig::Spread.new([2]), Twig::Spread.new([3]))
    end
  end

  context 'when method has a mix of positional and spread arguments' do
    let(:method_name) { :positional }

    it 'calls the method' do
      expect(callee).to receive(method_name).with(1, 2, 3)
      spreader.call(1, Twig::Spread.new([2, 3]))
    end
  end

  context 'when method has only kwargs' do
    let(:method_name) { :kwarg }

    it 'calls the method' do
      expect(callee).to receive(method_name).with({ a: 1, b: 2, c: 3 })
      spreader.call(a: 1, b: 2, c: 3)
    end
  end

  context 'when method has spread of kwargs' do
    let(:method_name) { :kwarg }

    it 'calls the method' do
      expect(callee).to receive(method_name).with({ a: 1, b: 2, c: 3 })
      spreader.call(Twig::Spread.new({ a: 1 }), Twig::Spread.new({ b: 2 }), Twig::Spread.new({ c: 3 }))
    end
  end

  context 'when method has both positional and kwargs' do
    let(:method_name) { :both }

    it 'calls the method' do
      expect(callee).to receive(method_name).with(1, 2, c: 3, d: 4)
      spreader.call(1, 2, c: 3, d: 4)
    end
  end

  context 'when method has spread positional and kwargs' do
    let(:method_name) { :both }

    it 'calls the method' do
      expect(callee).to receive(method_name).with(1, 2, c: 3, d: 4)
      spreader.call(Twig::Spread.new([1, 2]), Twig::Spread.new({ c: 3, d: 4 }))
    end
  end
end
