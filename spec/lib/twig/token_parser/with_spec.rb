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
