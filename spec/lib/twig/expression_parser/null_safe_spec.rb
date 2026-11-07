# frozen_string_literal: true

require 'spec_helper'

# Ported from Twig PHP's ExpressionParserTest::getTestsForNullSafeOperator
RSpec.describe 'the ?. null-safe operator' do
  def render(source, context)
    loader = Twig::Loader::Hash.new({ 'template' => source })

    Twig::Environment.new(loader, strict_variables: true).load('template').render(context)
  end

  [
    ['{{ foo?.bar }}', { foo: { bar: 'baz' } }, 'baz'],
    ['{{ foo?.bar }}', { foo: nil }, ''],
    ['{{ foo?.bar?.baz }}', { foo: { bar: { baz: 'qux' } } }, 'qux'],
    ['{{ foo?.bar?.baz }}', { foo: { bar: nil } }, ''],
    ['{{ foo?.bar?.baz }}', { foo: nil }, ''],
    ['{{ foo?.bar?.baz ?? "qux" }}', { foo: nil }, 'qux'],
    ['{{ foo?.bar ?? "qux" }}', { foo: { bar: 0 } }, '0'],
    # Twig Ruby prints false as "false", where Twig PHP prints ""
    ['{{ foo?.bar ?? "qux" }}', { foo: { bar: false } }, 'false'],
    ['{{ foo ?. bar }}', { foo: nil }, ''],
    ['{{ foo?.upcase() }}', { foo: 'a' }, 'A'],
    ['{{ foo?.upcase() }}', { foo: nil }, ''],
    ['{{ foo?.bar is defined ? "yes" : "no" }}', { foo: { bar: 1 } }, 'yes'],
    ['{{ foo?.bar is defined ? "yes" : "no" }}', { foo: nil }, 'no'],
    ['{{ foo[0]?.bar }}', { foo: [nil] }, ''],
    ['{{ (foo.empty?)?.to_s }}', { foo: [] }, 'true'],
    # A nil short-circuits the rest of the chain
    ['{{ foo?.bar.baz }}', { foo: nil }, ''],
    ['{{ foo?.bar.baz?.qux.corge }}', { foo: nil }, ''],
    ['{{ foo?.bar.baz?.qux.corge }}', { foo: { bar: { baz: nil } } }, ''],
    ['{{ foo?.bar.baz?.qux.corge }}', { foo: { bar: { baz: { qux: { corge: 1 } } } } }, '1'],
    ['{{ foo?.bar.upcase() }}', { foo: nil }, ''],
    ['{{ foo?.bar.baz ?? "x" }}', { foo: nil }, 'x'],
    # The default filter compiles its operand and its fallback twice
    ['{{ foo?.bar|default(foo?.baz) }}', { foo: nil }, ''],
    ['{{ foo?.bar|default(foo?.baz.qux) }}', { foo: nil }, ''],
    ['{{ foo?.bar|default(foo?.baz) }}', { foo: { bar: nil, baz: 'qux' } }, 'qux'],
    ['{{ foo?.bar|default(foo?.baz) }}', { foo: { bar: 'corge', baz: 'qux' } }, 'corge'],
    [
      '{% for foo in foos %}[{{ foo?.bar|default(foo?.baz) }}]{% endfor %}',
      { foos: [{ bar: 'corge', baz: 'grault' }, { baz: 'qux' }] },
      '[corge][qux]',
    ],
    ['{{ foo?.bar|default("x") }}', { foo: nil }, 'x'],
    ['{{ foo?.bar?.baz|default("z") }}', { foo: { bar: nil } }, 'z'],
    ['{{ foo?.bar?.baz|default("z") }}', { foo: { bar: { baz: 'y' } } }, 'y'],
  ].each do |source, context, expected|
    it "renders #{source} with #{context.inspect} as #{expected.inspect}" do
      expect(render(source, context)).to eq(expected)
    end
  end

  # Ported from Twig PHP's ExpressionParserTest::getTestForInvalidNullSafeOperatorShortCircuiting
  [
    ['{{ foo?.bar.baz }}', { foo: { bar: nil } }, 'baz'],
    ['{{ foo?.bar.baz?.qux.corge }}', { foo: { bar: { baz: { qux: nil } } } }, 'corge'],
  ].each do |source, context, attribute|
    it "only short-circuits on the object of a ?. in #{source}" do
      expect { render(source, context) }.to raise_error(
        Twig::Error::Runtime,
        /Impossible to access an attribute \("#{attribute}"\) on a null variable/
      )
    end
  end

  it 'still raises on an undefined variable' do
    expect { render('{{ foo?.bar }}', {}) }.to raise_error(Twig::Error::Runtime, /Variable "foo" does not exist/)
  end
end
