# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::Runtime::ArgumentSpreader do
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
      spreader.call(Twig::Runtime::Spread.new([1, 2, 3]))
    end
  end

  context 'when method has a spread of multiple positional arguments' do
    let(:method_name) { :positional }

    it 'calls the method' do
      expect(callee).to receive(method_name).with(1, 2, 3)
      spreader.call(Twig::Runtime::Spread.new([1]), Twig::Runtime::Spread.new([2]), Twig::Runtime::Spread.new([3]))
    end
  end

  context 'when method has a mix of positional and spread arguments' do
    let(:method_name) { :positional }

    it 'calls the method' do
      expect(callee).to receive(method_name).with(1, 2, 3)
      spreader.call(1, Twig::Runtime::Spread.new([2, 3]))
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
      spreader.call(
        Twig::Runtime::Spread.new({ a: 1 }),
        Twig::Runtime::Spread.new({ b: 2 }),
        Twig::Runtime::Spread.new({ c: 3 })
      )
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
      spreader.call(Twig::Runtime::Spread.new([1, 2]), Twig::Runtime::Spread.new({ c: 3, d: 4 }))
    end
  end

  context 'when the method takes a block' do
    let(:method) { ->(tag = 'div', cls: 'c', &block) { "<#{tag} class=#{cls}>#{block&.call}" } }

    it 'passes the block to a helper method' do
      result = spreader.call(Twig::Runtime::Spread.new(['p']), Twig::Runtime::Spread.new({ 'cls' => 'x' })) { 'F' }

      expect(result).to eq('<p class=x>F')
    end

    it 'passes the block to a Twig callable' do
      expect(described_class.new(method, {}).call(Twig::Runtime::Spread.new(['p'])) { 'F' }).to eq('<p class=c>F')
    end
  end

  context 'when binding names like a Twig callable' do
    let(:callee) do
      Class.new do
        def replace(value, from) = "#{value}:#{from}"
        def join(value, glue: '', and_glue: nil) = "#{value}:#{glue}:#{and_glue}"
        def three(value, a = 'A', b = 'B') = "#{value}#{a}#{b}"
        def kw3(a: 'A', b: 'B', c: 'C') = "#{a}#{b}#{c}"
      end.new
    end

    it 'binds positional arguments to keyword parameters in order' do
      spreader = described_class.new(callee.method(:kw3), {})

      expect(spreader.call(Twig::Runtime::Spread.new(['x']), Twig::Runtime::Spread.new({ 'c' => 'y' }))).to eq('xBy')
      expect(spreader.call(Twig::Runtime::Spread.new({ 'b' => 'y' }))).to eq('AyC')
    end

    it 'raises for a name bound to a keyword parameter a positional argument already took' do
      spreader = described_class.new(callee.method(:kw3), {})

      expect { spreader.call(Twig::Runtime::Spread.new(['x']), Twig::Runtime::Spread.new({ 'a' => 'y' })) }.
        to raise_error(ArgumentError, 'Named parameter $a overwrites previous argument')
      expect { spreader.call(Twig::Runtime::Spread.new({ 'a' => 'y' }), a: 'x') }.
        to raise_error(ArgumentError, 'Named parameter $a overwrites previous argument')
    end

    it 'raises for a name bound to a keyword parameter a spread positional argument already took' do
      spreader = described_class.new(callee.method(:join), {})

      expect { spreader.call('v', Twig::Runtime::Spread.new(['-']), Twig::Runtime::Spread.new({ 'glue' => '+' })) }.
        to raise_error(ArgumentError, 'Named parameter $glue overwrites previous argument')
    end

    it 'binds a name to a positional parameter' do
      expect(described_class.new(callee.method(:replace), {}).call('v', Twig::Runtime::Spread.new({ 'from' => 'f' }))).
        to eq('v:f')
    end

    it 'passes positional arguments past the positional parameters to the keyword parameters' do
      expect(described_class.new(callee.method(:join), {}).call('v', Twig::Runtime::Spread.new(['-', '+']))).
        to eq('v:-:+')
    end

    it 'binds a Twig name to the Ruby parameter it stands for' do
      spreader = described_class.new(callee.method(:join), { 'and' => :and_glue })

      expect(spreader.call('v', Twig::Runtime::Spread.new({ 'and' => '+' }))).to eq('v::+')
    end

    it 'raises for a name bound past an optional positional parameter, whose default Ruby cannot read' do
      expect { described_class.new(callee.method(:three), {}).call('v', Twig::Runtime::Spread.new({ 'b' => 'x' })) }.
        to raise_error(ArgumentError, /Argument "b" could not be assigned .* optional argument "a"/)
    end

    it 'raises for a name given twice' do
      spreader = described_class.new(callee.method(:join), {})
      spreads = [Twig::Runtime::Spread.new({ 'glue' => '+' }), Twig::Runtime::Spread.new({ 'glue' => '-' })]

      expect { spreader.call('v', *spreads) }.
        to raise_error(ArgumentError, 'Named parameter $glue overwrites previous argument')
    end
  end
end
