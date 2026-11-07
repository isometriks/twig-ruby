# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::TokenParser::Flush do
  def environment(template)
    Twig::Environment.new(Twig::Loader::Hash.new({ 'index' => template }))
  end

  it 'renders around a flush, like Twig' do
    template = 'a{% flush %}b{% for i in 1..2 %}{{ i }}{% flush %}{% endfor %}'

    expect(environment(template).load('index').render({})).to eq('ab12')
  end

  def flush_nodes(node)
    [node].grep(Twig::Node::Flush) +
      node.nodes.values.flat_map { |child| flush_nodes(child) }
  end

  it 'parses into a flush node with the line of the tag' do
    env = environment('')
    module_node = env.parse(env.tokenize(Twig::Source.new("a\n{% flush %}b", 'index')))

    expect(flush_nodes(module_node).map(&:lineno)).to eq([2])
    expect(env.compile_source(Twig::Source.new('a{% flush %}b', 'index'))).to include('# flush')
  end

  it 'takes no arguments' do
    expect { environment('a{% flush x %}b').load('index') }.to raise_error(
      Twig::Error::Syntax,
      'Unexpected token "name" of value "x" ("end of statement block" expected) in "index" at line 1 column 11.'
    )
  end
end
