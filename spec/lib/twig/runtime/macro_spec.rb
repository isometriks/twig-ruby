# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Runtime::Macro do
  let(:source) { Twig::Source.new('', 'index.twig') }
  let(:body) { ->(_call_context, args) { args } }
  let(:macro) { described_class.new('test', body, { 'a' => false, 'b' => true }) }

  it 'binds positional arguments by position and named arguments by name' do
    expect(macro.call({ 0 => 1, 'b' => 2 }, nil, source, 1)).to include('a' => 1, 'b' => 2)
    expect(macro.call({ 'b' => 2, 'a' => 1 }, nil, source, 1)).to include('a' => 1, 'b' => 2)
  end

  it 'expands spread arguments' do
    args = macro.call({ 0 => Twig::Runtime::Spread.new([1]), 1 => Twig::Runtime::Spread.new({ b: 2 }) }, nil, source, 1)

    expect(args).to include('a' => 1, 'b' => 2)
  end

  it 'expands the integer keys of a spread mapping as positional arguments' do
    args = macro.call({ 0 => Twig::Runtime::Spread.new({ 1 => 'z', 0 => 'y' }) }, nil, source, 1)
    expect(args).to include('a' => 'z', 'b' => 'y')

    args = macro.call({ 0 => Twig::Runtime::Spread.new(Twig::AutoHash.new.add(1).merge!('b' => 2)) }, nil, source, 1)
    expect(args).to include('a' => 1, 'b' => 2)

    expect { macro.call({ 0 => Twig::Runtime::Spread.new({ 'b' => 1, 0 => 2 }) }, nil, source, 3) }.
      to raise_error(
        Twig::Error::Runtime,
        'Positional arguments cannot be used after named arguments for macro "test" in "index.twig" at line 3.'
      )
  end

  it 'rejects a spread value that is neither a sequence nor a mapping' do
    expect { macro.call({ 0 => Twig::Runtime::Spread.new(nil) }, nil, source, 3) }.
      to raise_error(
        Twig::Error::Runtime,
        'Only sequences and mappings can be spread into the arguments of macro "test" in "index.twig" at line 3.'
      )
  end

  it 'collects extra arguments in the variadic argument' do
    macro = described_class.new('test', body, { 'a' => false }, 'rest')

    # A sequence, like PHP's list, unless a named argument is among them
    expect(macro.call({ 0 => 1, 1 => 2, 2 => 3 }, nil, source, 1)).to eq('a' => 1, 'rest' => [2, 3])
    expect(macro.call({ 0 => 1 }, nil, source, 1)).to eq('a' => 1, 'rest' => [])
    expect(macro.call({ 0 => 1, 1 => 2, 2 => 3, 'id' => 4 }, nil, source, 1)).
      to eq('a' => 1, 'rest' => { 0 => 2, 1 => 3, 'id' => 4 })
  end

  it 'hands the call context to the body' do
    macro = described_class.new('test', ->(call_context, _args) { call_context })

    expect(macro.call({}, :view, source, 1)).to eq(:view)
  end

  it 'rejects a named argument that repeats a positional one' do
    expect { macro.call({ 0 => 1, 'a' => 2 }, nil, source, 3) }.
      to raise_error(Twig::Error::Runtime, 'Argument "a" is defined twice for macro "test" in "index.twig" at line 3.')
  end

  it 'requires the arguments that have no default value' do
    expect { macro.call({ 'b' => 1 }, nil, source, 3) }.
      to raise_error(
        Twig::Error::Runtime,
        'Value for argument "a" is required for macro "test" in "index.twig" at line 3.'
      )
  end

  it 'rejects a positional argument after a named one' do
    expect { macro.call({ 'b' => 1, 0 => 2 }, nil, source, 3) }.
      to raise_error(
        Twig::Error::Runtime,
        'Positional arguments cannot be used after named arguments for macro "test" in "index.twig" at line 3.'
      )
  end

  context 'when rendered' do
    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          # Argument names that aren't valid Ruby parameter names
          '{% macro m(class, GET, self) %}{{ class }}{{ GET }}{{ self }}{% endmacro %}{{ _self.m(1, 2, 3) }}',
          '{% macro m(class, GET) %}{{ class }}{{ GET }}{% endmacro %}{{ _self.m(GET: 2, class: 1) }}',
          # Named arguments keep their name, even a reserved one
          '{% macro m(blocks, context) %}{{ blocks }}{{ context }}{% endmacro %}{{ _self.m(context: 2, blocks: 1) }}',
          '{% from _self import m %}{% macro m(blocks) %}{{ blocks }}{% endmacro %}{{ m(blocks: 1) }}',
          '{% macro m(a = null, b = 2) %}{{ a }}{{ b }}{% endmacro %}{{ _self.m(...[1]) }}{{ _self.m(...{ b: 3 }) }}',
          # Integer keys of a spread mapping are positional, as with PHP's array unpacking
          '{% macro m(a, b = 2) %}{{ a }}{{ b }}{% endmacro %}' \
          '{{ _self.m(...{ 0: "z" }) }}{{ _self.m(...{ 1: "z", 0: "y" }) }}',
          '{% macro m() %}{% endmacro %}{{ _self.template_reference is defined ? "KO" : "OK" }}',
          # A colon default (a Ruby extension) before a variadic
          '{% macro m(a: 1, ...rest) %}{{ a }}{{ rest|join }}{% endmacro %}{{ _self.m() }}{{ _self.m(2, 3, 4) }}',
          # A variadic forwarded to another macro
          '{% macro f(a, b = "B") %}[{{ a }}{{ b }}]{% endmacro %}' \
          '{% macro g(...rest) %}{{ _self.f(...rest) }}{% endmacro %}{{ _self.g(1, 2) }}{{ _self.g(1, b: 3) }}',
          # A sequence unless it holds a named argument, so it encodes like PHP's list
          '{% macro f(...rest) %}{{ rest|json_encode|raw }}{% endmacro %}' \
          '{{ _self.f(1, 2) }}{{ _self.f() }}{{ _self.f(x: 1) }}',
        ]
      end
      let(:outputs) { ['123', '12', '12', '1', '123', 'z2zy', 'OK', '1234', '[12][13]', '[1,2][]{"x":1}'] }
    end

    it 'does not reach the methods of the template' do
      loader = Twig::Loader::Hash.new({ 'index.twig' => '{{ _self.template_name() }}' })

      expect { Twig::Environment.new(loader).load('index.twig').render }.
        to raise_error(Twig::Error::Runtime, /Macro "template_name" is not defined in template "index.twig"/)
    end

    it 'keeps a macro imported inside a macro local to that macro' do
      loader = Twig::Loader::Hash.new({
        'a.twig' => '{% macro x() %}A{% endmacro %}',
        'b.twig' => '{% macro x() %}B{% endmacro %}',
        'index.twig' => '{% import "a.twig" as m %}{% macro f() %}{% import "b.twig" as m %}{{ m.x() }}{% endmacro %}' \
                        '{{ m.x() }}{{ _self.f() }}{{ m.x() }}{% block content %}{{ m.x() }}{% endblock %}',
      })

      expect(Twig::Environment.new(loader).load('index.twig').render).to eq('ABAA')
    end
  end
end
