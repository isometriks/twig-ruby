# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::NodeVisitor::Correctness do
  let(:environment) { Twig::Environment.new(Twig::Loader::Hash.new({ 'index' => '' })) }
  let(:source) { Twig::Source.new('', 'index') }
  let(:empty) { Twig::Node::Empty.new }

  # Traverses a child template whose body is the given node, as the parser does
  def traverse(body)
    module_node = Twig::Node::Module.new(
      Twig::Node::Body.new({ 0 => body }),
      Twig::Node::Expression::Constant.new('parent', 1),
      empty,
      empty,
      empty,
      Twig::AutoHash.new,
      source
    )

    Twig::NodeTraverser.new(environment, [described_class.new]).traverse(module_node).nodes[:body].nodes[0]
  end

  def nodes(*values)
    Twig::Node::Nodes.new(Twig::AutoHash.new.add(*values))
  end

  def constant(value)
    Twig::Node::Expression::Constant.new(value, 1)
  end

  describe 'a child template body' do
    it 'accepts a set without capture' do
      input = nodes(Twig::Node::Set.new(false, empty, empty, 1))

      expect(traverse(input)).to be(input)
    end

    it 'accepts a set capturing text' do
      input = nodes(Twig::Node::Set.new(true, empty, nodes(nodes(Twig::Node::Text.new('foo', 1))), 1))

      expect(traverse(input)).to be(input)
    end

    [' ', "\t", "\n", "\n\t\n   "].each do |blank|
      it "accepts a BOM followed by #{blank.inspect}" do
        input = Twig::Node::Text.new("\xEF\xBB\xBF#{blank}", 1)

        expect(traverse(input)).to be(input)
      end
    end

    {
      'text' => -> { Twig::Node::Text.new('foo', 1) },
      'print' => -> { Twig::Node::Print.new(constant('foo'), 1) },
      'include' => -> { Twig::Node::Include.new(constant('foo'), nil, false, false, 1) },
      'nested text' => -> { nodes(nodes(Twig::Node::Text.new('foo', 1))) },
    }.each do |description, input|
      it "rejects #{description}" do
        expect { traverse(instance_exec(&input)) }.to raise_error(
          Twig::Error::Syntax,
          /cannot include content outside Twig blocks/
        )
      end
    end
  end

  describe 'a block definition' do
    let(:templates) do
      {
        'base.twig' => '{% block content %}{% endblock %}',
        'child.twig' => template,
      }
    end
    let(:environment) { Twig::Environment.new(Twig::Loader::Hash.new(templates)) }

    def render
      environment.load('child.twig').render
    end

    context 'when nested under a tag at the root of a child template' do
      let(:template) do
        "{% extends 'base.twig' %}\n{% for i in 1..2 %}\n{% if true %}{% block content %}{% endblock %}{% endif %}" \
          "\n{% endfor %}"
      end

      it 'names the nearest tag' do
        expect { render }.to raise_error(
          Twig::Error::Syntax,
          'A "block" tag cannot be under a "if" tag (line 3) in "child.twig" at line 3.'
        )
      end
    end

    context 'when nested under a guard tag at the root of a child template' do
      let(:template) do
        "{% extends 'base.twig' %}\n\n{% guard filter upper %}{% block content %}{% endblock %}{% endguard %}"
      end

      it 'names the line of the guard tag' do
        expect { render }.to raise_error(
          Twig::Error::Syntax,
          'A "block" tag cannot be under a "guard" tag (line 3) in "child.twig" at line 3.'
        )
      end
    end

    context 'when content is output by a guard tag at the root of a child template' do
      let(:template) { "{% extends 'base.twig' %}\n\n{% guard filter upper %}foo{% endguard %}" }

      it 'reports the line of the guard tag' do
        expect { render }.to raise_error(Twig::Error::Syntax, /outside Twig blocks.* at line 3\?\z/)
      end
    end

    context 'when nested under a tag inside a macro of a child template' do
      let(:template) do
        "{% extends 'base.twig' %}{% macro m() %}{% if true %}{% block content %}OK{% endblock %}{% endif %}" \
          '{% endmacro %}'
      end

      it 'is allowed' do
        expect(render).to eq('OK')
      end
    end

    context 'when nested under a tag of a template that does not extend another one' do
      let(:template) { '{% if true %}{% block content %}OK{% endblock %}{% endif %}' }

      it 'is rendered in place' do
        expect(render).to eq('OK')
      end
    end
  end
end
