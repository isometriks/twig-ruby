# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Twig::NodeVisitor::SafeAnalysis do
  let(:attr_safe) { [:html_attr] }

  let(:environment) do
    safe = attr_safe

    Twig::Environment.new(Twig::Loader::Hash.new({})).tap do |env|
      env.add_extension(Class.new(Twig::Extension::Base) do
        define_method(:filters) do
          [Twig::TwigFilter.new('attr_safe', ->(value) { value }, { is_safe: safe })]
        end
      end.new)
    end
  end

  let(:safe_analysis) do
    environment.node_visitors.
      find { |visitor| visitor.is_a?(Twig::NodeVisitor::Escaper) }.
      send(:safe_analysis)
  end

  def parse(code, name = 'index')
    environment.parse(environment.tokenize(Twig::Source.new(code, name)))
  end

  it 'does not retain the nodes of parsed templates' do
    parse('{{ "a"|upper }}{{ foo.bar }}{{ [1, 2]|join("-") }}{{ b ? "y" : "n" }}', 'a')
    parse('{% autoescape "js" %}{{ foo|attr_safe }}{% endautoescape %}', 'b')

    expect(safe_analysis.send(:data)).to be_empty
  end

  it 'does not change the safe list of a filter' do
    parse('{{ foo|attr_safe }}{{ foo|attr_safe }}')
    parse('{% autoescape "html_attr" %}{{ foo|attr_safe }}{% endautoescape %}')

    expect(attr_safe).to eq([:html_attr])
  end
end
