# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::Types do
  let(:environment) { Twig::Environment.new(Twig::Loader::Hash.new({}), { autoescape: false }) }

  def types_node(template)
    stream = environment.tokenize(Twig::Source.new(template, ''))
    find_types(environment.parse(stream))
  end

  def find_types(node)
    return node if node.is_a?(Twig::Node::Types)

    node.nodes.each_value do |child|
      found = find_types(child)
      return found if found
    end

    nil
  end

  {
    'an empty mapping' => ['{% types {} %}', {}],
    'a simple mapping' => ['{% types {foo: "bar"} %}', { 'foo' => { type: 'bar', optional: false } }],
    'a trailing comma' => ['{% types {foo: "bar",} %}', { 'foo' => { type: 'bar', optional: false } }],
    'an optional name' => ['{% types {foo?: "bar"} %}', { 'foo' => { type: 'bar', optional: true } }],
    'an optional name with a spaced ?:' => ['{% types {foo ?: "bar"} %}', { 'foo' => { type: 'bar', optional: true } }],
    'multiple pairs with duplicate values' => [
      '{% types {foo: "foo", bar?: "foo", baz: "baz"} %}',
      {
        'foo' => { type: 'foo', optional: false },
        'bar' => { type: 'foo', optional: true },
        'baz' => { type: 'baz', optional: false },
      },
    ],
    'no enclosing braces' => [
      '{% types foo: "foo", bar?: "bar" %}',
      { 'foo' => { type: 'foo', optional: false }, 'bar' => { type: 'bar', optional: true } },
    ],
    'documentation comments' => [
      "{% types {\n## The foo variable\n## Used by the header\nfoo: \"bar\"\n} %}",
      { 'foo' => { type: 'bar', optional: false } },
    ],
    'regular comments' => [
      "{% types {\n# Not documentation\nfoo: \"bar\",\n} %}",
      { 'foo' => { type: 'bar', optional: false } },
    ],
  }.each do |description, (template, mapping)|
    it "parses #{description}" do
      expect(types_node(template).attributes[:mapping]).to eq(mapping)
    end
  end

  it 'keeps a type node per name with its own line' do
    node = types_node("{% types {\nfoo: 'foo',\nbar?: 'bar',\n} %}")

    expect(node.nodes['bar'].attributes).to eq({ name: 'bar', type: 'bar', optional: true })
    expect(node.nodes['bar'].lineno).to eq(3)
  end

  it_behaves_like 'render_and_assert' do
    let(:inputs) { ['a{% types {foo: "string", bar?: "int"} %}b', '{% types foo: "string" %}'] }
    let(:outputs) { ['ab', ''] }
  end

  {
    '{% types {foo: "a" bar: "b"} %}' => /\AA type string must be followed by a comma\.? Unexpected token "name"/,
    '{% types {foo "a"} %}' => /\AA type name must be followed by a colon \(:\)\.? Unexpected token "string"/,
    '{% types foo: "a" bar: "b" %}' => /\AA type string must be followed by a comma\.? Unexpected token "name"/,
    '{% types {foo: bar} %}' => /\AUnexpected token "name" of value "bar" \("string" expected\)/,
  }.each do |template, message|
    it "rejects #{template}" do
      expect { types_node(template) }.to raise_error(Twig::Error::Syntax, message)
    end
  end
end
