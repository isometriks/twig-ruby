# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::TokenParser::With do
  it_behaves_like 'render_and_assert' do
    let(:inputs) do
      <<~INPUTS
        {% with { str: "Hello" } only %}{{ str }}{% endwith %} {{ str }}
      INPUTS
    end

    let(:outputs) do
      <<~OUTPUTS
        Hello World!
        Hello World!
        Hello World!
      OUTPUTS
    end

    let(:locals) { { str: 'World!' } }
  end

  context 'with an iterable that is not a mapping' do
    let(:pairs_class) do
      Class.new do
        include Enumerable

        def each
          yield :foo, 'baz'
          yield 'bar', 'qux'
        end
      end
    end

    it_behaves_like 'render_and_assert' do
      let(:inputs) do
        [
          '{% with pairs %}{{ foo }}{{ bar }}{% endwith %}',
          "{% with ['a', 'b'] %}{{ _context[0] }}{{ _context[1] }}{% endwith %}",
          "{% with ['a', 'b'] only %}{{ _context|keys|join(',') }}{% endwith %}",
          '{% with [] %}ok{% endwith %}',
          '{% with 1..2 %}{{ _context[1] }}{% endwith %}',
        ]
      end

      let(:outputs) { %w[bazqux ab 0,1 ok 2] }
      let(:locals) { { pairs: pairs_class.new } }
    end

    ["'str'", '1', 'null', 'obj'].each do |value|
      it "raises for #{value}" do
        environment = Twig::Environment.new(Twig::Loader::Hash.new({
          'index' => "{% with #{value} %}x{% endwith %}",
        }))

        expect { environment.load('index').render({ obj: Object.new }) }.
          to raise_error(Twig::Error::Runtime, /Variables passed to the "with" tag must be a mapping/)
      end
    end
  end

  context 'when a global has the same name as a variable' do
    let(:environment) do
      Twig::Environment.new(Twig::Loader::Hash.new({ 'index' => template })).tap do |env|
        env.add_global('g', 'global')
      end
    end

    {
      "{% set g = 'local' %}{% with {a: 1} %}{{ g }}{% endwith %}" => 'local',
      "{% set g = 'local' %}{% with {a: 1} only %}{{ g }}{% endwith %}" => 'global',
      "{% set g = 'local' %}{% with {g: 'with'} %}{{ g }}{% endwith %}" => 'with',
    }.each do |source, output|
      context "with #{source.inspect}" do
        let(:template) { source }

        it "renders #{output.inspect}" do
          expect(environment.load('index').render).to eq(output)
        end
      end
    end
  end
end
