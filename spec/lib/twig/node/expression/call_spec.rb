# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Node::Expression::Call do
  it_behaves_like 'render_and_assert' do
    let(:extensions) do
      [
        Class.new(Twig::Extension::Base) do
          def filters
            [
              Twig::TwigFilter.new('foo', lambda(&:reverse)),
              Twig::TwigFilter.new('bar', ->(_value, **rest) { rest.inspect }, is_safe: [:all]),
            ]
          end
        end.new,
      ]
    end

    let(:inputs) do
      [
        '{{ "!dlroW olleH"|foo }}',
        '{{ nil|bar(hello: "world") }}',
      ]
    end

    let(:outputs) do
      [
        'Hello World!',
        '{hello: "world"}',
      ]
    end
  end

  let(:test_extension) do
    Class.new(Twig::Extension::Base) do
      def filters
        [
          # Required positional
          Twig::TwigFilter.new('bar', ->(_value, bar) { bar }),
          # Required kwarg
          Twig::TwigFilter.new('foo', ->(_value, bar:) { bar }),
          # Multiple required kwarg
          Twig::TwigFilter.new('baz', ->(_value, bar:, baz:) { [bar, baz].join('-') }),
          # kwargs spread
          Twig::TwigFilter.new('hash_spread', ->(_value, **bar) { bar.values.join('-') }),
        ]
      end
    end.new
  end

  context 'when there is an extra kwarg' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ ["a", "b"]|join(",", whatever="something") }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /Unknown argument "whatever" for filter "join\(glue, and\)"/ }
    end
  end

  context 'when there is an extra positional argument' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ ["a", "b"]|join(",", " and ", 2, 3, 4) }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /Unknown arguments "2", "3", "4" for filter "join\(glue, and\)"/ }
    end
  end

  context 'when there is a missing positional argument' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ [{a:"a"}, {a:"b"}]|column }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /value for argument "column" is required for filter "column"/i }
    end
  end

  context 'when there is a missing kwarg' do
    it_behaves_like 'render_and_raise' do
      before do
        environment.add_extension(test_extension)
      end

      let(:template) { '{{ "foo"|foo }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /value for argument "bar" is required for filter "foo"/i }
    end
  end

  context 'when there is required positional but passed a spread' do
    it_behaves_like 'render_and_assert' do
      let(:extensions) { [test_extension] }
      let(:inputs) { ['{{ "foo"|bar(...[1]) }}'] }
      let(:outputs) { ['1'] }
    end
  end

  context 'when there is required kwarg but passed a spread' do
    it_behaves_like 'render_and_assert' do
      let(:extensions) { [test_extension] }
      let(:inputs) { ['{{ "foo"|foo(...{bar: "hello"}) }}'] }
      let(:outputs) { ['hello'] }
    end
  end

  context 'when there are multiple required kwarg but passed a spread' do
    it_behaves_like 'render_and_assert' do
      let(:extensions) { [test_extension] }
      let(:inputs) { ['{{ "foo"|baz(...{bar: "hello", baz: "world"}) }}'] }
      let(:outputs) { ['hello-world'] }
    end
  end

  context 'when there is a hash spread' do
    it_behaves_like 'render_and_assert' do
      let(:extensions) { [test_extension] }
      let(:inputs) { ['{{ "foo"|hash_spread(...{bar: "hello", baz: "world"}) }}'] }
      let(:outputs) { ['hello-world'] }
    end
  end

  context 'when there is a hash spread but given a positional arg' do
    it_behaves_like 'render_and_raise' do
      before do
        environment.add_extension(test_extension)
      end

      let(:template) { '{{ "foo"|hash_spread({bar: "hello", baz: "world"}) }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /expected a hash spread for argument "bar" for filter "hash_spread"/i }
    end
  end

  describe 'binding arguments as Twig binds them' do
    let(:binding_extension) do
      Class.new(Twig::Extension::Base) do
        def filters
          [
            Twig::TwigFilter.new('three', ->(_v, a = 'A', b = 'B', c = 'C') { "#{a}#{b}#{c}" }),
            Twig::TwigFilter.new('camel', ->(_v, someValue = 'x') { someValue.to_s }), # rubocop:disable Naming/BlockParameterName, Naming/VariableName
            Twig::TwigFilter.new('snake', ->(_v, some_value = 'x') { some_value.to_s }),
          ]
        end

        def functions
          [
            Twig::TwigFunction.new('req', ->(a, b = 'B') { "#{a}#{b}" }),
            Twig::TwigFunction.new('req2', ->(a, b) { "#{a}#{b}" }),
          ]
        end
      end.new
    end

    it_behaves_like 'render_and_assert' do
      let(:extensions) { [binding_extension] }
      let(:inputs) do
        [
          '{{ "v"|camel(some_value: 1) }}',
          '{{ "v"|camel(someValue: 1) }}',
          '{{ "v"|camel(somevalue: 1) }}',
          '{{ "v"|snake(someValue: 1) }}',
          '{{ "v"|snake(some_value: 1) }}',
          '{{ "v"|three("a", b: "b") }}',
          '{{ [1, 2, 3]|join(and: " and ") }}',
          '{{ [1, 2, 3]|join(", ", and: " and ") }}',
          '{{ [1, 2, 3]|join(glue: ",", glue: "x") }}',
          '{{ [1, 2, 3]|join(and_glue: " and ") }}',
          '{{ [1, 2, 3]|join(...{and: " and "}) }}',
          '{{ req(...[1, 2]) }}',
        ]
      end
      let(:outputs) do
        ['1', '1', '1', '1', '1', 'abC', '12 and 3', '1, 2 and 3', '1x2x3', '12 and 3', '12 and 3', '12']
      end
    end

    {
      '{{ "v"|three(c: "c") }}' =>
        'Argument "c" could not be assigned for filter "three(a, b, c)" because it is mapped to a Ruby callable ' \
        'which cannot determine default value for optional arguments "a", "b" (use keyword parameters instead) ' \
        'in "template.twig" at line 1.',
      '{{ "v"|three("a", c: "c") }}' =>
        'Argument "c" could not be assigned for filter "three(a, b, c)" because it is mapped to a Ruby callable ' \
        'which cannot determine default value for optional argument "b" (use a keyword parameter instead) ' \
        'in "template.twig" at line 1.',
      '{{ req(1, a: 1) }}' => 'Argument "a" is defined twice for function "req" in "template.twig" at line 1.',
      '{{ req(1, b: 2, a: 1) }}' => 'Argument "a" is defined twice for function "req" in "template.twig" at line 1.',
      '{{ [1, 2]|join(",", glue: "-") }}' =>
        'Argument "glue" is defined twice for filter "join" in "template.twig" at line 1.',
      '{{ req(b: 2) }}' => 'Value for argument "a" is required for function "req" in "template.twig" at line 1.',
      '{{ req2(1) }}' => 'Value for argument "b" is required for function "req2" in "template.twig" at line 1.',
      '{{ req2(b: 1) }}' => 'Value for argument "a" is required for function "req2" in "template.twig" at line 1.',
      '{{ req(1, 2, c: 3) }}' => 'Unknown argument "c" for function "req(a, b)" in "template.twig" at line 1.',
      '{{ req(1, 2, c: 3, d_e: 4) }}' =>
        'Unknown arguments "c", "de" for function "req(a, b)" in "template.twig" at line 1.',
      '{{ req(1, 2, cC: 3) }}' => 'Unknown argument "cc" for function "req(a, b)" in "template.twig" at line 1.',
      '{{ [1, 2]|join(",", whatever="something", other=1) }}' =>
        'Unknown arguments "whatever", "other" for filter "join(glue, and)" in "template.twig" at line 1.',
      '{{ req(1, b: 2, ...[3]) }}' =>
        'Positional arguments cannot be used after named arguments for function "req" in "template.twig" at line 1.',
    }.each do |source, expected|
      context "when calling #{source}" do
        it_behaves_like 'render_and_raise' do
          before { environment.add_extension(binding_extension) }

          let(:template) { source }
          let(:error) { Twig::Error::Syntax }
          let(:message) { expected }
        end
      end
    end
  end
end
