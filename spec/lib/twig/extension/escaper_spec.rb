# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Extension::Escaper do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {{ "<h1>" }}
        {{ "<h1>"|e }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        <h1>
        &lt;h1&gt;
      OUTPUTS
    end
  end

  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      [
        '{{ "<h1>
hey</h1>"|nl2br }}',
        '{{ html|nl2br }}',
      ]
    end

    let(:outputs) do
      [
        "<h1><br />\nhey</h1>",
        "&lt;h1&gt;<br />\nhey&lt;/h1&gt;",
      ]
    end

    let(:locals) { { html: "<h1>\nhey</h1>" } }
  end

  describe '.escape_filter_is_safe' do
    def args(*nodes)
      Twig::Node::Nodes.new(Twig::AutoHash.new.add(*nodes))
    end

    let(:constant) { Twig::Node::Expression::Constant.new('js', 1) }
    let(:variable) { Twig::Node::Expression::Variable::Context.new('s', 1) }

    # Like Twig's escapeFilterIsSafe, which only looks at the first argument
    it 'is safe for the strategy given as a constant, for html without one, and for none otherwise' do
      expect(described_class.escape_filter_is_safe(args)).to eq([:html])
      expect(described_class.escape_filter_is_safe(args(constant))).to eq(['js'])
      expect(described_class.escape_filter_is_safe(args(variable))).to eq([])
      expect(described_class.escape_filter_is_safe(args(variable, Twig::Node::Expression::Constant.new('UTF-8', 1)))).
        to eq([])
    end

    it 'escapes the output of a filter that preserves safety after a variable strategy, like Twig' do
      extension = Class.new(Twig::Extension::Base) do
        def filters
          [Twig::TwigFilter.new('up', ->(string) { string.to_s.upcase }, preserves_safety: [:html])]
        end
      end
      environment = Twig::Environment.new(Twig::Loader::Hash.new({
        'index' => "{{ x|e(s)|up }}|{{ x|e('html')|up }}|{{ x|e|up }}",
      }))
      environment.add_extension(extension.new)

      expect(environment.load('index').render({ 'x' => '<b>', 's' => 'html' })).
        to eq('&amp;LT;B&amp;GT;|&LT;B&GT;|&LT;B&GT;')
    end
  end
end
