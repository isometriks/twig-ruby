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
