# frozen_string_literal: true

require 'spec_helper'
require 'integration_shared_examples'

RSpec.describe Twig::Template do
  let(:template) { described_class.new(double(Twig::Environment)) }

  context 'when a block is missing' do
    it_behaves_like 'render_and_raise' do
      let(:template) { '{{ block("missing") }}' }
      let(:error) { Twig::Error::Runtime }
      let(:message) { /Block "missing" on template/ }
    end
  end

  context 'when block() renders a block of another template that calls parent()' do
    it_behaves_like 'render_and_assert' do
      let(:input) { "{{ block('block1', 'theme') }}" }
      let(:templates) do
        {
          theme: "{% extends 'base' %}" \
                 '{% block block1 %}{{ parent() }}THEME1/{% endblock %}' \
                 '{% block block2 %}THEME2/{% endblock %}',
          base: "{% block block1 %}BASE1/{{ block('block2') }}{% endblock %}" \
                '{% block block2 %}BASE2/{% endblock %}',
        }
      end
      let(:output) { 'BASE1/THEME2/THEME1/' }
    end
  end

  context 'when block() renders a block whose nested block is not overridden' do
    it_behaves_like 'render_and_assert' do
      let(:input) { "{{ block('block1', 'theme') }}" }
      let(:templates) do
        {
          theme: "{% extends 'base' %}{% block block1 %}{{ parent() }}THEME1/{% endblock %}",
          base: "{% block block1 %}BASE1/{{ block('block2') }}{% endblock %}" \
                '{% block block2 %}BASE2/{% endblock %}',
        }
      end
      let(:output) { 'BASE1/BASE2/THEME1/' }
    end
  end

  context 'when macros are imported in a template body that was not rendered' do
    let(:message) do
      'Macros imported in the body of template "index" are not available because the body was not rendered; ' \
        'move the "import" or "from" tag inside the block or the macro that uses it in "index" at line 1.'
    end

    def environment_for(source)
      loader = Twig::Loader::Hash.new({ 'index' => source, 'macros' => '{% macro label() %}label{% endmacro %}' })
      Twig::Environment.new(loader)
    end

    def load(source)
      environment_for(source).load('index')
    end

    it 'reports them when a block is rendered on its own' do
      template = load('{% import "macros" as helpers %}{% block field %}{{ helpers.label() }}{% endblock %}')

      expect { template.render_block('field') }.to raise_error(Twig::Error::Runtime, message)
    end

    it 'uses macros imported in the block itself' do
      template = load('{% block field %}{% import "macros" as helpers %}{{ helpers.label() }}{% endblock %}')

      expect(template.render_block('field')).to eq('label')
    end

    it 'reports them when a macro is called on its own' do
      environment = environment_for('{% from "macros" import label %}{% macro row() %}{{ label() }}{% endmacro %}')
      template = environment.load('index').unwrap(environment)

      expect do
        template.macro_namespace.call('row', {}, Twig::Runtime::Context.new, 1, template.source_context)
      end.to raise_error(Twig::Error::Runtime, /Macros imported in the body of template "index" are not available/)
    end
  end

  context do
    before do
      allow(template).to receive(:source_context).and_return(
        double(Twig::Source, {
          name: 'test.twig',
          path: '/test.twig',
        })
      )
    end

    it 'requires a context to render' do
      expect { template.render({}) }.to raise_error(
        Twig::Error::Runtime,
        /Render must implement Twig::Runtime::Context/
      )
    end
  end
end
