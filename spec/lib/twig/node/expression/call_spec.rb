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
          # Required kwarg
          Twig::TwigFilter.new('foo', ->(_value, bar:) { bar }),
          # Required positional
          Twig::TwigFilter.new('bar', ->(_value, bar) { bar }),
          # Multiple required kwarg
          Twig::TwigFilter.new('baz', ->(_value, bar:, baz:) { [bar, baz].join('-') }),
        ]
      end
    end.new
  end

  context 'when there is an extra kwarg' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ ["a", "b"]|join(",", whatever="something") }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /unexpected argument "whatever" for filter "join"/i }
    end
  end

  context 'when there is an extra positional argument' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ ["a", "b"]|join(",", " and ", 2, 3, 4) }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /unexpected argument "2, 3, 4" for filter "join"/i }
    end
  end

  context 'when there is a missing positional argument' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ [{a:"a"}, {a:"b"}]|column }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /Missing argument "column" for filter "column"/ }
    end
  end

  context 'when there is a missing kwarg' do
    it_behaves_like 'render_and_raise' do
      before do
        environment.add_extension(test_extension)
      end

      let(:template) { '{{ "foo"|foo }}' }
      let(:error) { Twig::Error::Syntax }
      let(:message) { /Missing argument "bar" for filter "foo"/ }
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
end
